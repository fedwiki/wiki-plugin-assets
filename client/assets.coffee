
expand = (text)->
  text
    .replace /&/g, '&amp;'
    .replace /</g, '&lt;'
    .replace />/g, '&gt;'

context = ($item) ->
  sites = [location.host]
  journal = $item.parents('.page').data('data').journal
  for action in journal.slice(0).reverse()
    if action.site? and not sites.includes(action.site)
      sites.push action.site
  console.log 'context', sites
  sites

fetch = ($report, assets, remote) ->
  site = if remote? then "//#{remote}" else ''

  link = (file) ->
    """<a href="#{site}/assets/#{assets}/#{encodeURIComponent file}" target=_blank>#{expand file}</a>"""

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
      url: "#{site}/plugin/assets/list"
      data: {assets}
      dataType: 'json'
      success: render
      error: trouble

emit = ($item, item) ->
  uploader = ->
    return '' if $item.parents('.page').hasClass 'remote'
    """
      <div style="background-color:#ddd;" class="progress-bar" role="progressbar"></div>
      <center><button>upload</button></center>
      <input style="display: none;" type="file" name="uploads[]" multiple="multiple">
    """

  $item.append """
    <div style="background-color:#eee;padding:15px;">
      <dl style="margin:0;color:gray"></dl>
      #{uploader()}
    </div>
  """

  assets = item.text.match(/([\w\/-]*)/)[1]
  for site in context $item
    $report = $item.find('dl').prepend """
      <dt><img width=12 src="//#{site}/favicon.png"> #{site}</dt>
      <dd style="margin:8px;"></dd>
    """
    fetch $report.find('dd:first'), assets, site

bind = ($item, item) ->
  assets = item.text.match(/([\w\/-]*)/)[1]

  $item.dblclick -> wiki.textEditor $item, item

  # https://coligo.io/building-ajax-file-uploader-with-node/
  $button = $item.find 'button'
  $input = $item.find 'input'
  $progress = $item.find '.progress-bar'

  tick = (e) ->
    return unless e.lengthComputable
    percentComplete = e.loaded / e.total
    percentComplete = parseInt(percentComplete * 100)
    $progress.text "#{percentComplete}%"
    $progress.width "#{percentComplete}%"

  $button.click (e) ->
    $input.click()

  $input.on 'change', (e) ->
    files = $(this).get(0).files
    return unless files.length
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

