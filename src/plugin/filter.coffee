class Annotator.Plugin.Filter extends Annotator.Plugin
  # Events and callbacks to bind to the Filter#element.
  events:
    ".annotator-filter-property input focus": "_onFilterFocus"
    ".annotator-filter-property input blur":  "_onFilterBlur"
    ".annotator-filter-property input keyup": "_onFilterKeyup"

  # Common classes used to change plugin state.
  classes:
    active:   'annotator-filter-active'
    hl:
      hide:   'annotator-hl-filtered'
      active: 'annotator-hl-active'

  # HTML templates for the plugin UI.
  html:
    element: """
             <div class="annotator-filter">
               <strong>Navigate:</strong>
               <span class="annotator-filter-navigation">
                 <button class="annotator-filter-previous">Previous</button>
                 <button class="annotator-filter-next">Next</button>
               </span>
               <strong>Filter by:</strong>
             </div>
             """
    filter:  """
             <span class="annotator-filter-property">
               <label></label>
               <input/>
             </span>
             """

  # Default options for the plugin.
  options:
    # A CSS selector or Element to append the plugin toolbar to.
    appendTo: 'body'

    # Public: Determines if the property is contained within the provided
    # annotation property. Default is to split the string on spaces and only
    # return true if all keywords are contained in the string. This method
    # can be overridden by the user when initialising the plugin.
    #
    # string   - An input String from the fitler.
    # property - The annotation propery to query.
    #
    # Examples
    #
    #   plugin.option.getKeywords('hello', 'hello world how are you?')
    #   # => Returns true
    #
    #   plugin.option.getKeywords('hello bill', 'hello world how are you?')
    #   # => Returns false
    #
    # Returns an Array of keyword Strings.
    isFiltered: (input, property) ->
      return false unless input and property

      for keyword in (input.split /\s*/)
        return false if property.indexOf(keyword) == -1

      return true

  # Public: Creates a new instance of the Filter plugin.
  #
  # element - The Annotator element (this is ignored by the plugin).
  # options - An Object literal of options.
  #
  # Examples
  #
  #   filter = new Annotator.Plugin.Filter(annotator.element)
  #
  # Returns a new instance of the Filter plugin.
  constructor: (element, options) ->
    # As most events for this plugin are relative to the toolbar which is
    # not inside the Annotator#Element we override the element property.
    # Annotator#Element can still be accessed via @annotator.element.
    element = $(@html.element).appendTo(@options.appendTo)

    super element, options
    @filter  = $(@html.filter)
    @filters = {}
    this.updateHighlights()

  # Public: Created event listeners on the annotator object.
  #
  # Returns nothing.
  pluginInit: ->
    this._setupListeners()

  # Listens to annotation change events on the Annotator in order to refresh
  # the @annotations collection.
  # TODO: Make this more granular so the entire collection isn't reloaded for
  # every single change.
  #
  # Returns itself.
  _setupListeners: ->
    events = [
      'annotationsLoaded', 'annotationCreated',
      'annotationUpdated', 'annotationDeleted'
    ]

    for event in events
      @annotator.subscribe event, this.updateHighlights
    this

  # Public: Adds a filter to the toolbar. The filter must have both a label
  # and a property of an annotation object to filter on.
  #
  # options - An Object literal containing the filters options.
  #           label      - A public facing String to represent the filter.
  #           property   - An annotation property String to filter on.
  #           isFiltered - A callback Function that recieves the field input
  #                        value and the annotation property value. See
  #                        @options.isFiltered() for details.
  #
  # Examples
  #
  #   # Set up a filter to filter on the annotation.user property.
  #   filter.addFilter({
  #     label: User,
  #     property: 'user'
  #   })
  #
  # Returns itself to allow chaining.
  addFilter: (options) ->
    filter = $.extend({
      label: ''
      property: ''
      isFiltered: @options.isFiltered
    }, options)

    filter.id = 'annotator-filter-' + filter.property
    filter.annotations = []
    filter.element = @filter.clone().appendTo(@element)
    filter.element.find('label')
      .html(filter.label)
      .attr('for', filter.id)
    filter.element.find('input')
      .attr({
        id: filter.id
        placeholder: 'Filter by ' + filter.label + '\u2026'
      })

    @filters[filter.id] = filter
    this

  # Public: Updates the filter.annotations property. Then updates the state
  # of the elements in the DOM. Calls the filter.isFiltered() method to
  # determine if the annotation should remain.
  #
  # filter - A filter Object from @filters
  #
  # Examples
  #
  #   filter.updateFilter(myFilter)
  #
  # Returns itself for chaining
  updateFilter: (filter) ->
    filter.annotations = []

    this.updateHighlights()
    this.resetHighlights()
    input = $.trim filter.element.find('input').val()

    if input
      annotations = @highlights.map -> $(this).data('annotation')

      for annotation in $.makeArray(annotations)
        property = annotation[filter.property]
        if filter.isFiltered input, property
          filter.annotations.push annotation

      this.filterHighlights()

  # Public: Updates the @highlights property with the latest highlight
  # elements in the DOM.
  #
  # Returns a jQuery collection of the highlight elements.
  updateHighlights: =>
    @highlights = $('.annotator-hl')

  # Public: Runs through each of the filters and removes all highlights not
  # currently in scope.
  #
  # Returns itself for chaining.
  filterHighlights: ->
    filtered = []

    $.each @filters, ->
      $.merge(filtered, this.annotations)

    highlights = @highlights
    for annotation, index in filtered
      highlights = highlights.not(annotation.highlights)

    highlights.addClass(@classes.hl.hide)
    this

  # Public: Removes hidden class from all annotations.
  #
  # Returns itself for chaining.
  resetHighlights: ->
    @highlights.removeClass(@classes.hl.hide)
    this

  # Updates the filter field on focus.
  #
  # event - A focus Event object.
  #
  # Returns nothing
  _onFilterFocus: (event) =>
    $(event.target).parent().addClass(@classes.active)

  # Updates the filter field on blur.
  #
  # event - A blur Event object.
  #
  # Returns nothing.
  _onFilterBlur: (event) =>
    unless event.target.value
      $(event.target).parent().removeClass(@classes.active)

  # Updates the filter based on the id of the filter element.
  #
  # event - A keyup Event
  #
  # Returns nothing.
  _onFilterKeyup: (event) =>
    filter = @filters[event.target.id]
    this.updateFilter filter if filter