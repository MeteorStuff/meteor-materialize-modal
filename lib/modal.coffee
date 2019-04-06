
DEBUG = false

#
# Global translation methods & helpers.
#
@t9nIt = (string) ->
  T9n?.get?(string) or string


Template.registerHelper 'mmT9nit', (string) ->
  t9nIt(string)

#
# Create instance of MaterializeModal to handle event and
# modal construction logic.
#
MaterializeModal = new MaterializeModalClass()


###
#     Template.materializeModalContainer
###
Template.materializeModalContainer.helpers
  modalOptions: ->
    Template.currentData().get()


###
#     Template.materializeModal
###
Template.materializeModal.onCreated ->
  console.log("Template.materializeModal.onCreated", @data) if DEBUG

  if not M?
    # Hopefully this will warn someone trying to use this package without first including Materializecss !!!
    throw new Error("MaterializeModal requires Materializecss !!!")

  if M.openModal?
    throw new Error("MaterializeModal 1.1+ requires Materializecss v0.97.8 or greater!  Use 1.0 for earlier versions of Materializecss")



Template.materializeModal.onRendered ->
  console.log("Template.materializeModal.onRendered", @data.title)  if DEBUG

  #
  # (1) Update the jQuery handle of the modal instance with the latest
  #     modal DOM element.
  #
  MaterializeModal.$modal = @$('#materializeModal')

  #
  # (2) Compute modal animation duration.
  #     Fullscreen modals should appear instantly.
  #     Otherwise, 300ms transition.
  #
  if @data.fullscreen then inDuration = 0 else 300

  inDuration = @data.inDuration or 300

  #
  # (3) Call Materialize's openModal() method to make
  #     the modal content appear.
  #
  # Set a callback to handle destroying the materializeModal template
  # if the user "completes" the modal, for instance by clicking
  # the background.
  #
  MaterializeModal.$modal.modal
    dismissible: @data.dismissible          # Modal can be dismissed by clicking outside of the modal
    opacity: @data.opacity                  # Opacity of modal background
    in_duration: inDuration                 # Transition in duration
    out_duration: @data.outDuration or 200  # Transition out duration
    onOpenEnd: (modal, trigger) =>
      console.log("materializeModal: ready") if DEBUG
      @data.ready?()
    onCloseEnd: ->
      console.log("materializeModal: modal complete") if DEBUG
      MaterializeModal.close(false, null, false)
      MaterializeModal.complete()

  # I wish they would make up their mind...
  MaterializeModal.$modal.modal('open')

Template.materializeModal.onDestroyed ->
  console.log("Template.materializeModal.onDestroyed") if DEBUG


Template.materializeModal.helpers
  
  #
  # bodyTemplate: The name of the template that should be rendered
  #               in the modal's body area.
  #
  bodyTemplate: ->
    @bodyTemplate or null
  
  #
  # icon: Return a Material icon code for the Modal.
  #
  icon: ->
    if @icon
      @icon
    else
      console.log("icon: type", @type) if DEBUG
      switch @type
        when 'alert'
          'warning'
        when 'error'
          'error'
  
  #
  # modalFooter:
  #
  modalFooter: ->
    @footerTemplate or 'materializeModalFooter'
  
  #
  # modalFooterData:
  #
  modalFooterData: ->
    _.extend({}, @, @footerTemplateData)


Template.materializeModal.events

  "click #closeButton": (e, tmpl) ->
    e.preventDefault()
    console.log('closeButton') if DEBUG
    MaterializeModal.close(false)

  "submit form#materializeModalForm, click button#submitButton": (e, tmpl) ->
    e.preventDefault()
    form = tmpl.$('form#materializeModalForm')  # This returns the main form defined in this template
    if form.find('form')?.length > 0
      form = form.find('form')  # If the body contains a form then we use that.
    console.log('submit event:', e, "form:", form) if DEBUG
    MaterializeModal.close true,
      event: e
      form: form
    false # this prevents the page from refreshing on form submission!


Template.materializeModalForm.helpers
  #
  # isForm: Only true when the modal is a form.
  #
  isForm: ->
    @type in [ 'form', 'prompt' ]


Template.materializeModalStatus.helpers
  progressMessage: ->
    #....
