
expand = (text)->
  text
    .replace /&/g, '&amp;'
    .replace /</g, '&lt;'
    .replace />/g, '&gt;'

fetch = ($item, item) ->
  $p = $item.find('p')
  assets = item.text.match(/([\w\/-]*)/)[1]

  link = (file) ->
    """<a href="#{location.origin}/assets/#{assets}/#{encodeURIComponent file}" target=_blank>#{expand file}</a>"""

  render = (data) ->
    if data.error
      return $p.text "server reports: #{data.error.code}"
    files = data.files
    if files.length == 0
      return $p.text "no files among these assets"
    $p.html (link file for file in files).join "<br>"

  trouble = ->
    $p.text "can't get asset list"

  $.ajax
      url: '/plugin/assets/list'
      data: {assets}
      dataType: 'json'
      success: render
      error: trouble

emit = ($item, item) ->
  $item.append """
    <div style="background-color:#eee;padding:15px;">
      <p>fetching asset list</p>
      <div style="background-color:white;" class="progress-bar" role="progressbar"></div>
      <center><button>upload</button></center>
    </div>
    <input style="display: none;" type="file" name="uploads[]" multiple="multiple">
  """
  fetch $item, item

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
      error: ->
        $progress.text 'upload error'
        $progress.width '100%'
      xhr: ->
        xhr = new XMLHttpRequest
        xhr.upload.addEventListener 'progress', tick, false
        xhr

window.plugins.assets = {emit, bind} if window?
module.exports = {expand} if module?

