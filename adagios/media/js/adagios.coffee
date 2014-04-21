###
Generated by coffee-script, any changes should be made to the adagios.coffee file
###
#
# Allow radio inputs as button in regular form
# http://dan.doezema.com/2012/03/twitter-bootstrap-radio-button-form-inputs/
#
# This stops regular posting for buttons and assigns values to a hidden input
# to enable buttons as a radio.
#
root = exports ? this

root.epochToDate = (epoch) ->
  new Date(epoch * 1000)

root.dateToEpoch = (date) ->
  parseInt(date.getTime() / 1000)

root.dateStr = (date) ->
  date.getFullYear() + "-" + zeropad(date.getMonth()+1, 2) + "-" + zeropad(date.getDate(), 2)

root.zeropad = (number, length) ->
  result = number + ""
  result = "0#{result}" while result.length < length
  result

jQuery ->
  $('div.btn-group[data-toggle="buttons-radio"]').each ->
    group = $(this)
    form = group.parents("form").eq(0)
    name = group.attr("data-toggle-name")
    hidden = $("input[name=\"#{ name }\"]", form)
    $("button", group).each ->
      button = $(this)
      button.on "click", ->
        hidden.val $(this).val()

      button.addClass "active"  if button.val() is hidden.val()


jQuery ->
  $('input.livestatus').each ->
    $this = $(this)
    object_type = $this.attr('data-object-type')
    return false if object_type is undefined

    query_function = (query) ->
      adagios.objectbrowser.select2_objects_query object_type, query

    $this.select2
      minimumInputLength: 0
      query: query_function
    $this.css 'width', '400px'
    return true

$.extend $.fn.dataTableExt.oStdClasses,
  sSortAsc: "header headerSortDown"
  sSortDesc: "header headerSortUp"
  sSortable: "header"

(($) ->
  obIgnoreTables = [$("table#service-table")[0], $("table#contact-table")[0], $("table#host-table")[0], $("table#command-table")[0], $("table#timeperiod-table")[0]]
  filter_cache = {}
  object_types = ['service', 'servicegroup', 'host', 'hostgroup', 'contact', 'contactgroup', 'command', 'timeperiod']

  $.fn.dataTableExt.afnFiltering.push (oSettings, aData) ->
    # Disable filter for all tables except obIgnoreTables
    return true  if $.inArray(oSettings.nTable, obIgnoreTables) is -1

    # Default we show nothing
    object_type = oSettings["sTableId"].split("-")[0]
    cache_type = filter_cache[object_type]

    return true if cache_type is undefined

    # We are showing templates and this is everything with a name
    if cache_type is "2"
      if aData[1] isnt null and aData[1] isnt undefined
        return true

    if cache_type is "1" and aData[2] is "#{object_type}group" and aData[0] != "0"
      return true

    if cache_type is "0" and aData[2] is object_type and aData[0] != "0"
      return true

    # default no
    false

  $.fn.adagios_version = () ->
    $this = $(this)

    current_version = $('#current_version').text()
    $.getJSON("https://opensource.ok.is/cgi-bin/version.cgi?version=#{current_version}&callback=?", (data) ->
      this
    ).success( (data) ->
      $this.text data['version']
      $('a#version_info').attr 'href', data['link']
    )
    this

  $.fn.ob_check_datatable_column_visibility = () ->
    # Hide columns when we are small
    window_width = $(window).width()
    $(this).each ->
      $this = $(this)
      # Don't hide the service name TODO this is semi helpfull on small devices, no hostname appears
      dt = $this.dataTable()
      columns = dt.fnSettings().aoColumns.length
      # 4 Visible columns
      console.log $this.attr('id')
      if $this.attr('id') == 'service-table'
        if window_width < 470
          dt.fnSetColumnVis 3, false
          dt.fnSetColumnVis 4, false
          dt.fnSetColumnVis 5, false
          dt.fnSetColumnVis 6, true
          return this
        else
          dt.fnSetColumnVis 3, true
          dt.fnSetColumnVis 6, false
      if columns > 5
        dt.fnSetColumnVis(5, (window_width > 970))
      if columns > 4
        dt.fnSetColumnVis(4, (window_width > 470))


    this
  $.fn.adagios_datetimepicker = (start_time, end_time) ->
    $this = $(this)
    $this.data 'start_time', start_time
    $this.data 'end_time', end_time


    # Save some starting states
    $this.data 'start_time_epoch', start_time
    $this.data 'end_time_epoch', end_time
    $this.data 'start_time_obj', epochToDate start_time
    $this.data 'end_time_obj', epochToDate end_time

    $this.data 'start_hours', zeropad($this.data('start_time_obj').getHours()) + ":" +
            zeropad($this.data('start_time_obj').getMinutes())
    $this.data 'end_hours', zeropad($this.data('end_time_obj').getHours()) + ":" +
            zeropad($this.data('end_time_obj').getMinutes())

    for which in ['start', 'end']
      val = $this.data "#{which}_time_epoch"
      if ! $this.find("input[name=\"#{which}_time\"]").length
        $this.append "<input name=\"#{which}_time\" type=\"hidden\" value=\"#{val}\">"

      $this.find("input[name='#{which}_time_picker']").each ->
        $dateobj = $this.data "#{which}_time_obj"
        $(this).val root.dateStr $dateobj
        $(this).datepicker(format: gettext("yyyy-mm-dd") ).on 'changeDate', (ev) ->
          $dateobj.setYear ev.date.getFullYear()
          $dateobj.setMonth ev.date.getMonth()
          $dateobj.setDate ev.date.getDate()
          return false

      $this.find("input[name='#{which}_hours']")
        .val($this.data("#{which}_time_obj").getHours() + ":" + zeropad($this.data("#{which}_time_obj").getMinutes(), 2))
        .change
          which: which
        , (event) ->
          time = $(this).val()
          time_regex = /^\d{1,2}:\d{1,2}$/
          if !time_regex.test(time)
            $(this).parent().addClass 'error'
            return false
          time = time.split ':'
          time[0] = time[0] % 24
          time[1] = zeropad time[1] % 60, 2

          $(this).parent().removeClass 'error'
          $(this).val "#{time[0]}:#{time[1]}"
          $this.data("#{event.data.which}_time_obj").setHours time[0]
          $this.data("#{event.data.which}_time_obj").setMinutes time[1]
          true
    $this.submit ->
      for which in ['start', 'end']
        $this.find("input[name='#{which}_time']").val dateToEpoch($this.data("#{which}_time_obj"))
  #
  #     Creates a dataTable for adagios objects
  #
  #     aoColumns are used primarily for Titles
  #     example, aoColumns = [ { 'sTitle': 'Contact Name'}, { 'sTitle': 'Alias' } ]
  #
  #     
  $.fn.adagios_ob_configure_dataTable = (aoColumns, fetch) ->
    
    # Option column
    aoColumns.unshift
      sTitle: "register"
      bVisible: false
    ,
      sTitle: "name"
      bVisible: false
    ,
      sTitle: "object_type"
      bVisible: false
    ,
      sTitle: """<label rel="tooltip" title="Select All" id="selectall" class="checkbox"><input type="checkbox"></label>"""
      sWidth: "32px"

    $this = $(this)
    $this.data "fetch", fetch
    $this.data "aoColumns", aoColumns
    $this

  $.fn.adagios_ob_render_dataTable = ->
    $this = $(this)
    $this.dtData = []
    $this.fetch = $this.data("fetch")
    $this.aoColumns = $this.data("aoColumns")
    $this.jsonqueries = $this.fetch.length
    $.each $this.fetch, (f, v) ->
      object_type = v["object_type"]
      console.log """Populating #{ object_type } #{ $this.attr("id") }<br/>"""
      json_query_fields = ["id", "register", "name"]
      $.each v["rows"], (k, field) ->
        json_query_fields.push field["cName"]  if "cName" of field
        json_query_fields.push field["cAltName"]  if "cAltName" of field
        json_query_fields.push field["cHidden"]  if "cHidden" of field

      $.getJSON("../rest/pynag/json/get_objects",
        object_type: object_type
        with_fields: json_query_fields.join(",")
      , (data) ->
        count = data.length
        $.each data, (i, item) ->
          field_array = [
            item["register"],
            item["name"],
            object_type,
            """<input id="ob_mass_select" name="#{ item["id"] }" type="checkbox">"""
          ]
          $.each v["rows"], (k, field) ->
            cell = """<a href="edit/#{ item["id"] }" """
            cell += 'class="'
            if item["register"] is "0"
              cell += "dis-object"
            cell += '">'
            field_value = ""
            if "icon" of field
              cell += """<i class="#{ field.icon }"""
              if item["register"] is "0"
                cell += """ glyph-grey"""
              cell += """ "></i>"""
            if item[field["cName"]]
              field_value = item[field["cName"]]
            else
              field_value = item[field["cAltName"]]  if item[field["cAltName"]]
            field_value = field_value.replace("\"", "&quot;")
            field_value = field_value.replace(">", "&gt;")
            field_value = field_value.replace("<", "&lt;")
            if "truncate" not of field
                field["truncate"] = 50

            if field_value.length > (field["truncate"] + 3)
              cell += """<abbr rel="tooltip" title=" #{ field_value }">#{ field_value.substr(0, field["truncate"]) } ...</abbr>"""
            else
              cell += " #{field_value}"
            cell += "</a>"
            field_array.push cell
            if field["cName"] is v["rows"][v["rows"].length - 1]["cName"]
              $this.dtData.push field_array
              count--
      ).success(->
        $this.jsonqueries = $this.jsonqueries - 1
        if $this.jsonqueries is 0
          $("[rel=tooltip]").tooltip()
          $this.data "dtData", $this.dtData
          $this.adagios_ob_dtPopulate()
          checked = $("input#ob_mass_select:checked").length
          $("#bulkselected").html checked
          if checked > 0
            $("#actions #modify a").removeClass('disabled')
          else
            $("#actions #modify a").addClass('disabled')
      ).error (jqXHR) ->


      # TODO - fix this to a this style

      #targetDataTable = $(this).data('datatable');
      #targetDataTable.parent().parent().parent().html('<div class="alert alert-error"><h3>ERROR</h3><br/>Failed to fetch data::<p>URL: ' + this.url + '<br/>Server Status: ' + jqXHR.status + ' ' + jqXHR.statusText + '</p></div>');
      this


  
  #
  #     Populates the datatable
  #
  #     jsonFields are used for describing which fields to fetch via json and how to handle them
  #     example, jsonFields = [ { 'cName': "command_name", 'icon_class': "glyph-computer-proces" }, ... ]
  #
  #     object_type is one of contact, command, host, service, timeperiod
  #     example, object_type = host
  #     
  $.fn.adagios_ob_dtPopulate = ->
    $this = $(this)
    object_type = $this.attr('id').split("-")[0]
    dtData = $this.data("dtData")
    aoColumns = $this.data("aoColumns")
    $("##{ object_type }-tab #loading").hide()
    console.log "Hiding ##{ object_type }-tab #loading"
    dt = $this.dataTable(
      aoColumns: aoColumns
      sPaginationType: "bootstrap"
      # "sScrollY":"260px",
      # "bAutoWidth":true,
      bAutoWidth:false
      bScrollCollapse: false
      bPaginate: true
      iDisplayLength: 100
      aaData: dtData
      sDom: "<'row-fluid'<'span7'<'toolbar_#{ object_type }'>>'<'span5'f>r>t<'row-fluid'<'span6'i><'span6'p>>"
      # Callback which assigns tooltips to visible pages
      fnDrawCallback: ->
        $("[rel=tooltip]").tooltip()
        $("input").click ->
          checked = $("input#ob_mass_select:checked").length
          $("#bulkselected").html checked
          if checked > 0
            $("#actions #modify a").removeClass('disabled')
          else
            $("#actions #modify a").addClass('disabled')
    )

    dt.ob_check_datatable_column_visibility()
    # Unbind sorting on the first visible column
    $("table\##{ object_type }-table th:first").unbind "click"

    $(".toolbar_#{ object_type }").html """
    <div class="row-fluid">
      <div class="span12"></div>
    </div>
    """

    $(".toolbar_#{ object_type } div.row-fluid div.span12").append """
        <div class="pull-left" id="actions">
          <div id="add" class="btn-group pull-left">
            <a href="#{BASE_URL}objectbrowser/add/#{object_type}" class="btn capitalize">
              Add #{object_type}
            </a>
            <a href="#" class="btn dropdown-toggle" data-toggle="dropdown">
              <i class="caret"></i>
            </a>
            <ul class="dropdown-menu nav">
              <li class="nav-header">Add</li>
            </ul>
          </div>
          <div id="modify" class="btn-group pull-left">
            <a rel="tooltip" id="copy" title="Copy" class="btn btn-important" data-target-bulk="bulk_copy" data-target="copy"><i class="icon-copy"></i></a>
            <a rel="tooltip" id="update" title="Edit" class="btn" data-target-bulk="bulk_edit" data-target="edit"><i class="glyph-pencil"></i></a>
            <a rel="tooltip" id="delete" title="Delete" class="btn" data-target-bulk="bulk_delete" data-target="delete"><i class="glyph-bin"></i></a>
          </div>
          <div id="view_filter" class="btn-group pull-right"></div>
        </div>

        """
    if object_type == "command" or object_type == "timeperiod"
      $("#view_filter").hide()

    $("#actions #modify a").on "click", (e) ->
      checked = $("input#ob_mass_select:checked").length
      if checked > 1
        params = {}
        swhat = $(this).attr('data-target-bulk')
        $form = $("form[name=\"bulk\"]")
        $form.attr "action", swhat
        $("table tbody input:checked").each (index) ->
          $("<input>").attr(
            type: "hidden"
            name: "change_" + $(this).attr("name")
            value: "1"
          ).appendTo $form

        $form.submit()
      else if checked > 0
        where = $(this).attr('data-target')
        id = $("table tbody input:checked").attr('name')
        window.location.href = window.location.href.split("#")[0] + "#{where}/#{id}"
      e.preventDefault()

    if (object_type != "command" and object_type != "timeperiod")
      $(".toolbar_#{ object_type } div.row-fluid ul.dropdown-menu").append """
      <li><a href="#{BASE_URL}objectbrowser/add/#{ object_type}group" class="capitalize">#{object_type}group</a></li>
      <li class="divider"></li>"""
      $(".toolbar_#{ object_type } div#view_filter.btn-group").append """
      <a rel="tooltip" title="Show #{ object_type }s" class="btn active" data-filter-type="0">
        <i class="glyph-computer-service"></i>
      </a>
      <a rel="tooltip" title="Show #{ object_type }groups" class="btn" data-filter-type="1">
        <i class="glyph-parents"></i>
      </a>
      <a rel="tooltip" title="Show #{ object_type } templates" class="btn" data-filter-type="2">
        <i class="glyph-cogwheels"></i>
      </a>"""

      filter_cache[object_type] = "0"

    for ot in object_types
      if ot is object_type or ot is "#{object_type}group"
        continue
      $(".toolbar_#{ object_type } div.row-fluid ul.dropdown-menu").append """
      <li class="capitalize"><a href="#{BASE_URL}objectbrowser/add/#{ ot }">#{ ot }</a></li>
      """

    $(".toolbar_#{ object_type } div.row-fluid ul.dropdown-menu").append """
      <li class="divider"></li>
      <li><a href="#{BASE_URL}objectbrowser/add/template" class="capitalize">Template</a></li>
    """
    $("#" + object_type + "-tab.tab-pane label#selectall").on "click", (e) ->
      $checkbox = $("#" + object_type + "-tab.tab-pane #selectall input")
      if $checkbox.prop "checked"
        $(".tab-pane.active .dataTable input#ob_mass_select").each ->
          $(this).prop "checked", true
      else
        $(".tab-pane.active .dataTable input#ob_mass_select").each ->
          $(this).prop "checked", false

      checked = $("input#ob_mass_select:checked").length
      $("#bulkselected").html checked
      if checked > 0
        $("#actions #modify a").removeClass('disabled')
      else
        $("#actions #modify a").addClass('disabled')

    # When inputs are selected in toolbar, we call redraw on the datatable which calls the filtering routing
    #        above 
    $("[class^=\"toolbar_\"] div#view_filter.btn-group a").on "click", (e) ->
      $target = $(this)
      e.preventDefault()
      return false  if $target.hasClass("active")
      object_type = $target.parentsUntil(".tab-content", ".tab-pane").attr("id").split("-")[0]
      $target.siblings().each ->
        $(this).removeClass "active"

      $target.addClass "active"
      filter_cache[object_type] = $target.attr('data-filter-type')
      $("table#" + object_type + "-table").dataTable().fnDraw()
      false

    $("div\##{object_type}_filter.dataTables_filter input").addClass "input-medium search-query"

    if object_type == "service"
      dt.fnSort [[4, "asc"], [5, "asc"]]
    else
      dt.fnSort [[4, "asc"]]

  
  #return this.each(function() {
  
  #
  #     Object Browser, This runs whenever "Run Check Plugin" is clicked
  #
  #     It resets the color of the OK/WARNING/CRITICAL/UNKNOWN button
  #     Runs a REST call to run the check_command and fetch the results
  #
  #     Calling button/href needs to have data-object-id="12312abc...."
  #     
  $.fn.adagios_ob_run_check_command = (click_event) ->
    
    # Fetch the calling object
    modal = $(this)
    
    # Get the object_id
    id = modal.attr("data-object-id")
    object_type = modal.attr("data-object-type")
    unless id
      console.log "Error, no data-object-id for run command"
      click_event.preventDefault()
      return false
    
    # Reset the class on the button
    $("#run_check_plugin #state").removeClass "label-important"
    $("#run_check_plugin #state").removeClass "label-warning"
    $("#run_check_plugin #state").removeClass "label-success"
    $("#run_check_plugin #state").html gettext("Pending")
    $("#run_check_plugin #output pre").html gettext("Executing check plugin")
    plugin_execution_time = $("#run_check_plugin div.progress").attr("data-timer")
    if plugin_execution_time > 1
      updateTimer = ->
        step += 1
        $("#run_check_plugin div.bar").css "width", step * 5 + "%"
        setTimeout updateTimer, step * steps  if step < 20
      $("#run_check_plugin div.progress").show()
      bar = $("#run_check_plugin div.bar")
      step = 0
      steps = (plugin_execution_time / 20) * 100
      updateTimer()
    
    # Run the command and fetch the output JSON via REST
    
    # Default to unknown if data[0] is less than 3
    
    # Set the correct class for state coloring box
    
    # Fill it up with the correct status
    
    # Put the plugin output in the correct div
    
    # Show the refresh button
    run_check_plugin_div = $("div#run_check_plugin")

    # Assign this command to the newly shown refresh button
    $.getJSON(BASE_URL + "rest/pynag/json/run_check_command",
      object_id: id
    , (data) ->
      statusLabel = "label-inverse"
      statusString = "Unknown"
      if object_type is "host"
        if data[0] > 1
          statusLabel = "label-important"
          statusString = "DOWN"
        else
          statusLabel = "label-success"
          statusString = "UP"
      else
        if data[0] is 2
          statusLabel = "label-important"
          statusString = "Critical"
        if data[0] is 1
          statusLabel = "label-warning"
          statusString = "Warning"
        if data[0] is 0
          statusLabel = "label-success"
          statusString = "OK"
      run_check_plugin_div.find("#state").addClass statusLabel
      run_check_plugin_div.find("#state").html statusString
      if data[1]
        run_check_plugin_div.find("div#output pre").text data[1]
      else
        run_check_plugin_div.find("#output pre").html gettext("No data received on stdout")
      if data[2]
        run_check_plugin_div.find("#error #error_content").text data[2]
        run_check_plugin_div.find("#error #error_title").text gettext("Plugin output (standard error)")
        run_check_plugin_div.find("div#error").show()
      else
        run_check_plugin_div.find("#error pre").text = ""
        run_check_plugin_div.find("div#error").hide()
      run_check_plugin_div.find("div#plugin_output").show()
      run_check_plugin_div.find("dl").show()

      $("#run_check_plugin_refresh").show()
      run_check_plugin_div.find("div.progress").hide()
      $("#run_check_plugin_refresh").unbind('click').click  (click_event) ->
        $(this).adagios_ob_run_check_command(click_event)

    ).error (jqXHR) ->
      run_check_plugin_div = $("div#run_check_plugin")
      run_check_plugin_div.find("#error_title").text gettext("Error fetching JSON")
      run_check_plugin_div.find("#error_content").text gettext("Failed to fetch data") + ": URL: \"" + @url + "\" Server Status: \"" + jqXHR.status + "\" Status: \"" + jqXHR.statusText + "\""
      run_check_plugin_div.find("#error").show()
      run_check_plugin_div.find("div#plugin_output").hide()
      run_check_plugin_div.find("dl").hide()


    # Stop the button from POST'ing
    this
) jQuery

fatalError = (errorTitle, errorContent, errorFooter) ->
  $('div.container-fluid.content').html """
  <div class="row-fluid">
    <div class="span4">
      <div class="alert alert-error">
        <h2>Fatal Error - #{errorTitle}</h2>
        <div>#{errorContent}</div>
        <div>#{errorFooter}</div>
      </div>
    </div>
  </div>
    """

# https://docs.djangoproject.com/en/dev/ref/contrib/csrf/
getCookie = (name) ->
  cookieValue = null
  if document.cookie and document.cookie isnt ""
    cookies = document.cookie.split(";")
    i = 0

    while i < cookies.length
      cookie = jQuery.trim(cookies[i])

      # Does this cookie string begin with the name we want?
      if cookie.substring(0, name.length + 1) is (name + "=")
        cookieValue = decodeURIComponent(cookie.substring(name.length + 1))
        break
      i++
  cookieValue
window.csrftoken = getCookie 'csrftoken'

$(document).ready ->
  $("[rel=tooltip]").popover()
  $("#popover").popover()
  $("select").select2({
    placeholder: gettext("Select an item"),
    containerCssClass: "select2field"
  })

  # Disable clicking on disabled links
  $("body").on "click", "a.disabled", (event) ->
     event.preventDefault()
     return



  $('div.modal#notifications div.alert').bind 'close', (e) ->
    $this = $(this)
    id = $this.attr 'data-notification-dismiss'
    console.log "dismissing id #{id}"
    if $this.data 'dismissed'
      return true
    if id
      $.post "#{BASE_URL}rest/adagios/txt/clear_notification", { notification_id: id }
      ,(data) ->
        num_notifications = 0
        if data == "success"
          $('span#num_notifications').each ->
            num = +$(this).text()
            num_notifications = num - 1
            $(this).text num_notifications
          console.log "Notifications #{num_notifications}"
          if num_notifications == 0
            $('a[href="#notifications"] div.badge').removeClass 'badge-warning'
            $('div#notifications.modal div.modal-body').text "No notifications"
          $this.data 'dismissed', 1
          $this.alert 'close'
        else
          console.log "Unable to dismiss notification for #{id}"
      return e.preventDefault()
    true


