
DEBUG = false


class @MaterializeModalClass

  defaults:
    title: 'Message'
    message: ''
    type: 'message'
    closeLabel: null
    submitLabel: 'ok'
    inputSelector: '#prompt-input'
    callback: null


  constructor: ->
    #
    # templateOptions:  Setting this reactive var will automatically
    #                   cause materializeModalContainer to re-render.
    #                   It starts with a default value of no modal content.
    @templateOptions = new ReactiveVar()
    #
    # $modal:           This is a jQuery handle on the #materializeModal
    #                   DOM node itself.  This is the object we call
    #                   .openModal() and .closeModal() on.
    #
    @$modal = null


  #
  # injectContainer:  This method makes sure there is one copy
  #                   of materializeModalContainer in the body
  #                   to hold the modal content.
  #                   Notice we do not create duplicates.
  #
  injectContainer: ->
    @modalContainer = Blaze.renderWithData(Template.materializeModalContainer, @templateOptions, document.body) if not @modalContainer?


  #
  # open(options):  Display a modal with the options specified by
  #                 the options argument.
  #                 These will usually be generated by the methods
  #                 below.
  #
  open: (options) ->
    console.log("MaterializeModal.open()", @) if DEBUG
    #
    # (1) Make sure there's a modal container.
    #
    @injectContainer()
    #
    # (2) Update the this.options ReactiveVar, which will
    #     cause the dynamic Template inside materializeModalContainer
    #     to re-render.
    #
    @templateOptions.set options


  #
  # close( submit, context ): Close the modal.
  #                           Do not destroy materializeModalContainer.
  #                           - submit is a bool that determines whether
  #                             doSubmitCallback or doCancelCallback is called.
  #                           - context is the data that might be relevant to
  #                             the submitCallback, such as the submitted form.
  #
  close: (submit=false, context=null) ->
    console.log "MaterializeModal.close()" if DEBUG
    if @templateOptions.get()? # if there are no options, there is no modal -- there is nothing to close!
      #
      # If the user willingly submitted the modal,
      # run doSubmitCallback with context.
      #
      if submit
        cbSuccess = @doSubmitCallback(context)
      else
        cbSuccess = @doCancelCallback()
      #
      # If the callback had no errors, close the modal.
      #
      if cbSuccess
        @$modal.closeModal
          complete: =>
            @templateOptions.set null


  #
  # MaterializeModal common modal types:
  #
  #
  display: (options = {}) ->
    _.defaults options,
      message: null
      title: null
      submitLabel: null
      closeLabel: t9nIt 'cancel'
    , @defaults
    @open options


  message: (options = {}) ->
    _.defaults options,
      message: t9nIt 'You need to pass a message to materialize modal!'
      title: t9nIt 'Message'
      submitLabel: t9nIt 'ok'
    , @defaults
    @open options


  alert: (options = {}) ->
    _.defaults options,
      type: 'alert'
      message: t9nIt 'Alert'
      title: t9nIt 'Alert'
      label: t9nIt "Alert"
      bodyTemplate: "materializeModalAlert"
      submitLabel: t9nIt 'ok'
      @defaults
    @open options


  error: (options = {}) ->
    _.defaults options,
      type: 'error'
      message: t9nIt 'Error'
      title: t9nIt 'Error'
      label: t9nIt "Error"
      bodyTemplate: "materializeModalError"
      submitLabel: t9nIt 'ok'
    , @defaults
    @open options


  confirm: (options = {}) ->
    _.defaults options,
      type: 'confirm'
      message: t9nIt 'Message'
      title: t9nIt 'Confirm'
      closeLabel: t9nIt 'cancel'
      submitLabel: t9nIt 'ok'
    , @defaults
    @open options


  prompt: (options = {}) ->
    _.defaults options,
      type: 'prompt'
      message: t9nIt 'Feedback?'
      title: t9nIt 'Prompt'
      bodyTemplate: 'materializeModalPrompt'
      closeLabel: t9nIt 'cancel'
      submitLabel: t9nIt 'submit'
      placeholder: t9nIt "Type something here"
    , @defaults
    @open options


  loading: (options = {}) ->
    _.defaults options,
      message: t9nIt 'Loading'
      title: null
      bodyTemplate: 'materializeModalLoading'
      submitLabel: t9nIt 'cancel'
    , @defaults
    @open options


  progress: (options = {}) ->
    if not options.progress?
      Materialize.toast t9nIt "Error: No progress value specified!", 3000, "red"
    else
      options.progress = parseInt(100 * options.progress).toString() + "%" # prettify progress value!
      _.defaults options,
        message: null
        title: null
        bodyTemplate: 'materializeModalProgress'
        submitLabel: t9nIt 'close'
      , @defaults
      @open options


  form: (options = {}) ->
    console.log("form options", options) if DEBUG
    if not options.bodyTemplate?
      Materialize.toast(t9nIt("Error: No bodyTemplate specified!"), 3000, "red")
    else
      _.defaults options,
        type: 'form'
        title: t9nIt("Edit Record")
        submitLabel: '<i class="material-icons left">save</i>' + t9nIt('save')
        closeLabel: '<i class="material-icons left">&#xE033;</i>' + t9nIt('cancel')
      , @defaults

      if options.smallForm
        options.size = 'modal-sm'
        options.btnSize = 'btn-sm'
      @open options


  addValueToObjFromDotString: (obj, dotString, value) ->
    path = dotString.split(".")
    tmp = obj
    lastPart = path.pop()
    for part in path
      # loop through each part of the path adding to obj
      if not tmp[part]?
        tmp[part] = {}
      tmp = tmp[part]
    if lastPart?
      tmp[lastPart] = value


  #
  # fromForm: Given the jQuery handle to a form element,
  #           parse the inputs to create a dictionary
  #           representing the current value of each input.
  #           Note that only form inputs with a unique name
  #           attribute will be parsed.
  #
  fromForm: (form) ->
    console.log("fromForm", form, form?.serializeArray()) if DEBUG
    result = {}
    for key in form?.serializeArray()
      @addValueToObjFromDotString(result, key.name, key.value)

    # Override the result with the boolean values of checkboxes, if any
    for check in form?.find "input:checkbox"
      if $(check).prop('name')
        result[$(check).prop('name')] = $(check).prop 'checked'
    console.log("fromForm result", result) if DEBUG
    result


  #
  # doCancelCallback:   This only gets called if the user closes the
  #                     modal without submitting or confirming.
  #                     It will return submit: false to the callback, if there
  #                     is one.
  #
  doCancelCallback: ->
    options = @templateOptions.get()
    return true unless options.callback?

    try
      console.log("materializeModal: doCancelCallback") if DEBUG
      response =
        submit: false
      options.callback(null, response)
    catch error
      options.callback(error, null)
    true


  # doSubmitCallback:   This only gets called if the user sapiently submits
  #                     the modal -- clicking submit, hitting enter, etc.
  #                     It will parse any prompt or form data, if applicable.
  #                     It will return submit: true to the callback, if there
  #                     is one.
  #
  doSubmitCallback: (context) ->
    options = @templateOptions.get()
    return true unless options.callback?

    try
      response =
        submit: true

      switch options.type
        when 'prompt'
          response.value = $(options.inputSelector).val()
        when 'form'
          if context.form?
            response.form = @fromForm(context.form)
            response.value = response.form

      try
        options.callback(null, response)
      catch error
        console.error("MaterializeModal Callback returned Error", error)
        Materialize.toast(error.reason, 3000, 'toast-error')
        return false

    catch error
      options.callback(error, null)
    true


### Loading, Status, Progress code etc.

  status: (message, callback, title = 'Status', cancelText = 'Cancel') ->
    @_setData message, title, "materializeModalstatus",
      message: message
    @callback = callback
    @set("submitLabel", cancelText)
    @_show()


  updateProgressMessage: (message) ->
    if DEBUG
      console.log("updateProgressMessage", $("#progressMessage").html(), message)
    if $("#progressMessage").html()?
      $("#progressMessage").fadeOut 400, ->
        $("#progressMessage").html(message)
        $("#progressMessage").fadeIn(400)
    else
      @set("message", message)

###
