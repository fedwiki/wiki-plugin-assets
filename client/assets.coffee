
expand = (text)->
  text
    .replace /&/g, '&amp;'
    .replace /</g, '&lt;'
    .replace />/g, '&gt;'

link = (file) ->
  """<a href="#{location.origin}/assets/#{encodeURIComponent file}" target=_blank>#{expand file}</a>"""

fetch = ($item, item) ->
  $p = $item.find('p')

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
      dataType: 'json'
      success: render
      error: trouble

emit = ($item, item) ->
  $item.append """
    <p style="background-color:#eee;padding:15px;">
      fetching asset list
    </p>
  """
  fetch $item, item

bind = ($item, item) ->
  $item.dblclick -> wiki.textEditor $item, item

window.plugins.assets = {emit, bind} if window?
module.exports = {expand} if module?

