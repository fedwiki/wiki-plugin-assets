
expand = (text)->
  text
    .replace /&/g, '&amp;'
    .replace /</g, '&lt;'
    .replace />/g, '&gt;'

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

fetch = ($report, assets, remote) ->
  requestSite = if remote? then remote else null
  assetsURL = wiki.site(requestSite).getDirectURL('assets')
  if assetsURL is ''
    $report.text "site not currently reachable."
    return

  link = (file) ->
    """<a href="#{assetsURL}/#{if assets is '' then "" else assets + "/"}#{encodeURIComponent file}" target=_blank>#{expand file}</a>"""

  render = (data) ->
    if data.error
      return $report.text "no files" if data.error.code == 'ENOENT'
      return $report.text "plugin reports: #{data.error.code}"
    files = data.files
    if files.length == 0
      return $report.text "no files"
    $report.html (link file for file in files).join "<br>"

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
      <center><button class="copy">copy</button></center>
      <input style="display: none;" type="file" name="uploads[]" multiple="multiple">
    """

  $item.append """
    <div style="background-color:#eee;padding:15px; margin-block-start:1em; margin-block-end:1em;">
      <dl style="margin:0;color:gray"></dl>
      #{uploader()}
    </div>
  """

  assets = item.text.match(/([\w\/-]*)/)[1]
  for site in context $item
    $report = $item.find('dl').prepend """
      <dt><img width=12 src="#{wiki.site(site).flag()}"> #{site}</dt>
      <dd style="margin:8px;"></dd>
    """
    fetch $report.find('dd:first'), assets, site

bind = ($item, item) ->
  assets = item.text.match(/([\w\/-]*)/)[1]

  $item.dblclick -> wiki.textEditor $item, item

  # https://coligo.io/building-ajax-file-uploader-with-node/
  $button = $item.find '.upload'
  $copy = $item.find '.copy'
  $input = $item.find 'input'
  $progress = $item.find '.progress-bar'

  ignore = (e) ->
    e.preventDefault()
    e.stopPropagation()

  tick = (e) ->
    return unless e.lengthComputable
    percentComplete = e.loaded / e.total
    percentComplete = parseInt(percentComplete * 100)
    $progress.text "#{percentComplete}%"
    $progress.width "#{percentComplete}%"

  $button.click (e) ->
    $input.click()

  $copy.click (e) ->
    console.log('clicked the copy button!')
    # Find fully qualified url
    $.ajax
      url: '//scad.fed.wiki/assets/pages/candle-tilt/IMG_3804.JPG'
      type: 'GET'
      success: (data, status, xhr) ->
        console.log(xhr)
        # data in the array seems to get to server, but it is the wrong type
        file = new File(
          [data],
          'IMG_3804.JPG',
          { type: xhr.getResponseHeader('Content-Type') }
        )

        form = new FormData()
        form.append 'assets', assets
        form.append 'uploads[]', file, file.name

        $.ajax
          url: '/plugin/assets/upload'
          type: 'POST'
          data: form
          processData: false
          contentType: false
          success: ->
            $item.empty()
            # plugin refresh
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

window.plugins.assets = {emit, bind} if window?
module.exports = {expand} if module?
