const expand = text => {
  return text.replace(/&/g, '&amp;').replace(/</g, '&lt;').replace(/>/g, '&gt;')
}

const ignore = e => {
  e.preventDefault()
  e.stopPropagation()
}

const context = $item => {
  const sites = [location.host]
  const remote = $item.parents('.page').data('site')
  if (remote && remote !== location.host) {
    sites.push(remote)
  }
  const journal = $item.parents('.page').data('data').journal
  for (const action of journal.slice(0).reverse()) {
    if (action.site && !sites.includes(action.site)) {
      sites.push(action.site)
    }
  }
  console.log('context', { sites })
  return sites
}

const post_upload = ($item, item, form) => {
  const $progress = $item.find('.progress-bar')

  const tick = e => {
    if (!e.lengthComputable) return
    let percentComplete = e.loaded / e.total
    percentComplete = parseInt(percentComplete * 100)
    $progress.text(`${percentComplete}%`)
    $progress.width(`${percentComplete}%`)
  }

  $.ajax({
    url: '/plugin/assets/upload',
    type: 'POST',
    data: form,
    processData: false,
    contentType: false,
    success: () => {
      console.log('post success')
      $item.empty()
      $item.off()
      emit($item, item)
      bind($item, item)
    },
    error: e => {
      console.log('error', e)
      $progress.text(`upload error: ${e.statusText} ${e.responseText || ''}`)
      $progress.width('100%')
    },
    xhr: () => {
      const xhr = new XMLHttpRequest()
      xhr.upload.addEventListener('progress', tick, false)
      xhr.overrideMimeType('text/html')
      return xhr
    },
  })
}

const get_file = ($item, item, url, success) => {
  let assets = item.text.match(/([\w/-]*)/)[1]
  if (assets === 'PAGE') {
    assets = '/pages/' + $item.parents('.page')[0].id.split('_rev')[0]
  }
  const filename = url.split('/').reverse()[0]
  fetch(url)
    .then(response => response.blob())
    .then(blob => {
      const file = new File([blob], filename, { type: blob.type })

      const form = new FormData()
      form.append('assets', assets)
      form.append('uploads[]', file, file.name)
      success(form)
    })
    .catch(e => {
      const $progress = $item.find('.progress-bar')
      $progress.text(`Copy error: ${e.message}`)
      $progress.width('100%')
    })
}

const delete_file = ($item, item, url) => {
  const file = url.split('/').reverse()[0]
  let assets = item.text.match(/([\w/-]*)/)[1]
  if (assets === 'PAGE') {
    assets = '/pages/' + $item.parents('.page')[0].id.split('_rev')[0]
  }
  $.ajax({
    url: `/plugin/assets/delete?file=${file}&assets=${assets}`,
    type: 'POST',
    success: () => {
      $item.empty()
      $item.off()
      emit($item, item)
      bind($item, item)
    },
    error: e => {
      const $progress = $item.find('.progress-bar')
      $progress.text(`Delete error: ${e.statusText} ${e.responseText || ''}`)
      $progress.width('100%')
    },
  })
}

const fetch_list = ($item, item, $report, assets, remote, assetsData) => {
  const requestSite = remote ?? null
  const assetsURL = wiki.site(requestSite).getDirectURL('assets')
  if (assetsURL === '') {
    $report.text('site not currently reachable.')
    return
  }

  const link = file => {
    const href = `${assetsURL}/${assets === '' ? '' : assets + '/'}${encodeURIComponent(file)}`
    // todo: no action if not logged on
    const act = !isOwner
      ? ''
      : remote !== location.host
        ? '<button class="copy">⚑</button> '
        : '<button class="delete">✕</button> '

    return `<span>${act}<a href="${href}" target=_blank>${expand(file)}</a></span>`
  }

  const render = data => {
    assetsData[assets] ??= {}
    if (data.error) {
      if (data.error.code == 'ENOENT') return $report.text('no files')
      return $report.text(`plugin reports: ${data.error.code}`)
    }
    const files = data.files
    assetsData[assets][assetsURL] = files

    if (files.length === 0) {
      return $report.text('no files')
    }
    $report.html(files.map(file => link(file)).join('<br>'))

    $report.find('button.copy').on('click', e => {
      const href = $(e.target).parent().find('a').attr('href')
      get_file($item, item, href, form => {
        post_upload($item, item, form)
      })
    })

    $report.find('button.delete').on('click', e => {
      const href = $(e.target).parent().find('a').attr('href')
      delete_file($item, item, href)
    })
  }

  const trouble = e => {
    $report.text(`plugin error: ${e.statusText} ${e.responseText || ''}`)
  }

  $.ajax({
    url: wiki.site(requestSite).getURL('plugin/assets/list'),
    data: { assets },
    dataType: 'json',
    success: render,
    error: trouble,
  })
}

const emit = ($item, item) => {
  const uploader = () => {
    if ($item.parents('.page').hasClass('remote')) return ''
    return `
      <div style="background-color:#ddd;" class="progress-bar" role="progressbar"></div>
      <center><button class="upload">upload</button></center>
      <input style="display: none;" type="file" name="uploads[]" multiple="multiple">
    `
  }

  const assetsData = {}
  $item.addClass('assets-source')
  $item.get(0).assetsData = () => assetsData

  let assets = item.text.match(/([\w/-]*)/)[1]

  if (assets === 'PAGE') {
    if ($item.parents('.page')[0].id.endsWith('template')) {
      $item.append(`
        <div style="background-color:#eee;padding:15px; margin-block-start:1em; margin-block-end:1em;">
          <p><i>This asset item will use a folder name derived from the title of the created page.</i></p>
        </div>
      `)
      return
    } else {
      assets = '/pages/' + $item.parents('.page')[0].id.split('_rev')[0]
    }
  }

  $item.append(`
    <div style="background-color:#eee;padding:15px; margin-block-start:1em; margin-block-end:1em;">
      <dl style="margin:0;color:gray"></dl>
      ${uploader()}
    </div>
  `)

  for (const site of context($item)) {
    const $report = $item.find('dl').prepend(`
        <dt> <img width=12 src = "${wiki.site(site).flag()}" > ${site}</dt>
          <dd style="margin:8px;"></dd>
          `)
    fetch_list($item, item, $report.find('dd:first'), assets, site, assetsData)
  }
}

const bind = ($item, item) => {
  let assets = item.text.match(/([\w/-]*)/)[1]
  if (assets === 'PAGE') {
    assets = '/pages/' + $item.parents('.page')[0].id.split('_rev')[0]
  }

  $item.on('dblclick', () => wiki.textEditor($item, item))

  // https://coligo.io/building-ajax-file-uploader-with-node/
  const $button = $item.find('.upload')
  const $input = $item.find('input')

  $button.on('click', () => {
    $input.click()
  })

  $input.on('change', e => {
    upload($(e.target).get(0).files)
  })

  $item.on('dragover', ignore)
  $item.on('dragenter', ignore)
  $item.on('drop', e => {
    ignore(e)
    console.log('dropped', e)
    upload(e.originalEvent.dataTransfer?.files)
  })

  const upload = files => {
    console.log('upload', files)
    if (!files?.length) return
    const form = new FormData()
    form.append('assets', assets)
    for (const file of files) {
      form.append('uploads[]', file, file.name)
    }
    post_upload($item, item, form)
  }
}

if (typeof window !== 'undefined') {
  window.plugins.assets = { emit, bind }
}

export const assets = typeof window == 'undefined' ? { expand } : undefined
