
expand = (text)->
  text
    .replace /&/g, '&amp;'
    .replace /</g, '&lt;'
    .replace />/g, '&gt;'

ignore = (e) ->
  e.preventDefault()
  e.stopPropagation()

context = ($item) ->
  sites = [location.host]
  if remote = $item.parents('.page').data('site')
    unless remote == location.host
      sites.push remote
  journal = $item.parents('.page').data('data').journal
  for action in journal.slice(0).reverse()
    if action.site? and not sites.includes(action.site)
      sites.push action.site
  sites

post_upload = ($item, item, form) ->
  $progress = $item.find '.progress-bar'

  tick = (e) ->
    return unless e.lengthComputable
    percentComplete = e.loaded / e.total
    percentComplete = parseInt(percentComplete * 100)
    $progress.text "#{percentComplete}%"
    $progress.width "#{percentComplete}%"

  $.ajax
    url: '/plugin/assets/upload'
    type: 'POST'
    data: form
    processData: false
    contentType: false
    success: ->
      $item.empty()
      emit $item, item
      bind $item, item
    error: (e) ->
      console.log 'error', e
      $progress.text "upload error: #{e.statusText} #{e.responseText||''}"
      $progress.width '100%'
    xhr: ->
      xhr = new XMLHttpRequest
      xhr.upload.addEventListener 'progress', tick, false
      xhr

get_file = ($item, item, url, success) ->
  assets = item.text.match(/([\w\/-]*)/)[1]
  if assets is 'PAGE'
    assets = "/pages/" + $item.parents('.page')[0].id.split('_rev')[0]
  filename = url.split('/').reverse()[0]
  fetch(url).then((response) ->
    response.blob()
  ).then((blob) ->
    file = new File(
      [blob],
      filename,
      { type: blob.type }
    )

    form = new FormData()
    form.append 'assets', assets
    form.append 'uploads[]', file, file.name
    success form
  ).catch((e) ->
    $progress = $item.find '.progress-bar'
    $progress.text "Copy error: #{e.message}"
    $progress.width '100%'
  )


delete_file = ($item, item, url) ->
  file = url.split('/').reverse()[0]
  assets = item.text.match(/([\w\/-]*)/)[1]
  if assets is 'PAGE'
    assets = "/pages/" + $item.parents('.page')[0].id.split('_rev')[0]
  $.ajax
    url: "/plugin/assets/delete?file=#{file}&assets=#{assets}"
    type: 'POST'
    success: () ->
      $item.empty()
      emit $item, item
      bind $item, item
    error: (e) ->
      $progress = $item.find '.progress-bar'
      $progress.text "Delete error: #{e.statusText} #{e.responseText||''}"
      $progress.width '100%'

fetch_list = ($item, item, $report, assets, remote, assetsData) ->
  requestSite = if remote? then remote else null
  assetsURL = wiki.site(requestSite).getDirectURL('assets')
  if assetsURL is ''
    $report.text "site not currently reachable."
    return

  link = (file) ->
    href = "#{assetsURL}/#{if assets is '' then "" else assets + "/"}#{encodeURIComponent file}"
    # todo: no action if not logged on
    act = unless isOwner
      ''
    else if remote != location.host
      '<button class="copy">⚑</button> '
    else
      '<button class="delete">✕</button> '
    
    """<span>#{act}<a href="#{href}" target=_blank>#{expand file}</a></span>"""

  render = (data) ->
    assetsData[assets] ||= {}
    if data.error
      return $report.text "no files" if data.error.code == 'ENOENT'
      return $report.text "plugin reports: #{data.error.code}"
    files = data.files
    assetsData[assets][assetsURL] = files

    if files.length == 0
      return $report.text "no files"
    $report.html (link file for file in files).join "<br>"

    $report.find('button.copy').on 'click', (e) ->
      href = $(e.target).parent().find('a').attr('href')
      get_file $item, item, href, (form) ->
        post_upload $item, item, form

    $report.find('button.delete').on 'click', (e) ->
      href = $(e.target).parent().find('a').attr('href')
      delete_file $item, item, href

  trouble = (e) ->
    $report.text "plugin error: #{e.statusText} #{e.responseText||''}"

  $.ajax
    url: wiki.site(requestSite).getURL('plugin/assets/list')
    data: {assets}
    dataType: 'json'
    success: render
    error: trouble

emit = ($item, item) ->
  uploader = ->
    return '' if $item.parents('.page').hasClass 'remote'
    """
      <div style="background-color:#ddd;" class="progress-bar" role="progressbar"></div>
      <center><button class="upload">upload</button></center>
      <input style="display: none;" type="file" name="uploads[]" multiple="multiple">
    """

  assetsData = {}
  $item.addClass 'assets-source'
  $item.get(0).assetsData = -> assetsData

  assets = item.text.match(/([\w\/-]*)/)[1]

  if assets is 'PAGE'
    if $item.parents('.page')[0].id.endsWith('template')
      $item.append """
        <div style="background-color:#eee;padding:15px; margin-block-start:1em; margin-block-end:1em;">
          <p><i>This asset item will use a folder name derived from the title of the created page.</i></p>
        </div>
      """
      return
    else
      assets = "/pages/" + $item.parents('.page')[0].id.split('_rev')[0]

  $item.append """
    <div style="background-color:#eee;padding:15px; margin-block-start:1em; margin-block-end:1em;">
      <dl style="margin:0;color:gray"></dl>
      #{uploader()}
    </div>
  """

  for site in context $item
    $report = $item.find('dl').prepend """
      <dt><img width=12 src="#{wiki.site(site).flag()}"> #{site}</dt>
      <dd style="margin:8px;"></dd>
    """
    fetch_list $item, item, $report.find('dd:first'), assets, site, assetsData


bind = ($item, item) ->
  assets = item.text.match(/([\w\/-]*)/)[1]
  if assets is 'PAGE'
    assets = "/pages/" + $item.parents('.page')[0].id.split('_rev')[0]

  $item.on 'dblclick', () -> wiki.textEditor $item, item

  # https://coligo.io/building-ajax-file-uploader-with-node/
  $button = $item.find '.upload'
  $input = $item.find 'input'

  $button.on 'click', (e) ->
    $input.click()

  $input.on 'change', (e) ->
    upload $(this).get(0).files

  $item.on 'dragover', ignore
  $item.on 'dragenter', ignore
  $item.on 'drop', (e) ->
    ignore e
    upload e.originalEvent.dataTransfer?.files

  upload = (files) ->
    return unless files?.length
    form = new FormData()
    form.append 'assets', assets
    for file in files
      form.append 'uploads[]', file, file.name
    post_upload $item,item,form

window.plugins.assets = {emit, bind} if window?
module.exports = {expand} if module?
