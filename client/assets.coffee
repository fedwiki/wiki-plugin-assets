
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
      console.log data.error
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
      <form id="uploadForm" enctype="multipart/form-data" method="post" name="uploadForm" novalidate>
          <input type="file" name="userPhoto" id="userPhoto" />
          <button>submit</button>
      </form>
    </div>
  """
  fetch $item, item

bind = ($item, item) ->
  $item.dblclick -> wiki.textEditor $item, item

  $item.find('button').click (e) ->
    e.preventDefault()
    console.log 'click'
    form = new FormData($("#uploadForm")[0])
    console.log 'form data', form
    $.ajax
      url: '/plugin/assets/upload'
      method: "POST"
      dataType: 'json'
      data: form
      processData: false
      contentType: false
      success: -> console.log('success')
      error: -> console.log('error')

window.plugins.assets = {emit, bind} if window?
module.exports = {expand} if module?

