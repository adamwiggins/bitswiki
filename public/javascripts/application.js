//------------------------------------------------------------------------------
// Initialization
//------------------------------------------------------------------------------

Event.observe(window, 'load', initialize, false)
function initialize() {
	drawerManager.initialize()
	if($('compare_button'))
		versionManager.examineCompareButton()
}

//------------------------------------------------------------------------------
// Drawer Manager
//------------------------------------------------------------------------------

drawerManager = {
	drawers: [ ],
	drawerLinks: { },
	accessKeys: { },
	focusMap: {
		edit: "edit_content",
		search: "search_box"
	},
	
	duration: function(id) {
		return Element.getDimensions(id).height / 4300 + 0.15
	},

	openDrawer: function(id) {
		this.closeAll()
		Effect.SlideDown(id, { duration: this.duration(id), queue: 'end', afterFinish: this.setFocus })
		if (id == 'edit') { // hack around firefox textarea scroll bar issue
			Effect.Fade('edit_content_dummy', { duration: 0, queue: 'end' })
			Effect.Appear('edit_content', { duration: 0, queue: 'end' })
		}
		this.makeLinks(id)
	},

	closeDrawer: function() {
		this.closeAll()
		this.makeLinks('')
	},

	toggleDrawer: function(id) {
		if (!Element.visible(id)) this.openDrawer(id)
		else this.closeDrawer()
	},

	closeAll: function() {
		this.drawers.each(function(value, index) {
			if (Element.visible(value)) {
				if (value == 'edit') { // hack around firefox textarea scroll bar issue
					Element.hide('edit_content')
					Element.show('edit_content_dummy')
				}
				Effect.SlideUp(value, { duration: drawerManager.duration(value), queue: 'front' })
			}
		})
		Field.focus('emptyfocus')
	},

	makeLinks: function(id) {
		this.drawers.each(function(value, index) {
			text = (value == 'edit') ? $('edit_link_text').innerHTML : value
			if (value == id) {
				$('drawer_link_'+value).update('<a id="open_drawer" href="javascript:drawerManager.closeDrawer()">'+text+'</a>')
				$('open_drawer').setAttribute('accesskey', drawerManager.accessKeys[value])
			} else
				$('drawer_link_'+value).update(drawerManager.drawerLinks[value])
		})
	},
	
	setFocus: function(obj) {
		id = obj.element.id
		if (drawerManager.focusMap[id]) {
			Field.focus(drawerManager.focusMap[id])
		}
	},

	initialize: function() {
		active = null
		document.getElementsByClassName('drawer').each(function(value, index) {
			drawerManager.drawers.push(value.id)
			if ($('drawer_link_'+value.id)) {
				drawerManager.drawerLinks[value.id] = $('drawer_link_'+value.id).innerHTML
				drawerManager.accessKeys[value.id] = $('drawer_link_'+value.id+'_a').getAttribute("accesskey")
			}
			if (Element.visible(value.id) && active == null) active = value.id
		})
		drawerManager.makeLinks(active)

		// hack around firefox textarea scroll bar issue
		// (starting elements in reverse visibilities for graceful javascript degredation)
		if (active != 'edit' && $('edit_content') && $('edit_content_dummy')) {
			Element.hide('edit_content')
			Element.show('edit_content_dummy')
		}
	}
}

//------------------------------------------------------------------------------
// Version Manager
//------------------------------------------------------------------------------

versionManager = {
	getSelectedVersions: function(selected) {
		var boxes = new Array()
		var elements = $('compare_form').elements
		boxes.selected_index = -1

		for (var i = 0; i < elements.length; i++)
			if (elements[i].name == "compare[]" && elements[i].checked) {
				if (elements[i] == selected) boxes.selected_index = boxes.length
				boxes.push(elements[i])
			}

		return boxes
	},

	ensureSelectedVersions: function() {
		var boxes = this.getSelectedVersions()
		if (boxes.length == 2)
			return true
		else {
			alert("You must select two versions to compare.")
			return false
		}
	},

	checked: function(checkbox) {
		if (!checkbox.checked) {
			$('compare_button').disabled = true
			return
		}

		var selections = this.getSelectedVersions()
		if (selections.length > 2)
			for (var i = 0; i < selections.length; i++)
				if (selections[i] != checkbox)
					selections[i].checked = false

		this.examineCompareButton()
	},

	examineCompareButton: function() {
		var boxes = this.getSelectedVersions()
		$('compare_button').disabled = (boxes.length != 2)
	}
}

//------------------------------------------------------------------------------
// Edit Manager
//------------------------------------------------------------------------------

editManager = {
	cancel: function() {
		drawerManager.closeDrawer()
	},
	
	editTags: function() {
		Element.show('edit_tags')
		Element.hide('tags_content')
		Element.hide('edit_tags_action')
		Field.focus('edit_tags_textarea')
	},

	cancelTags: function() {
		Element.hide('edit_tags')
		Element.show('tags_content')
		Element.show('edit_tags_action')
		Field.focus('emptyfocus')
	},
	
	editPreview: function(url, value) {
		new Ajax.Request(url,
			{
				asynchronous: true,
				evalScripts: true,
				parameters: 'edit_content=' + escape(value)
			}
		)
	}
}

//------------------------------------------------------------------------------
// Comment Manager
//------------------------------------------------------------------------------

commentManager = {
	add: function() {
		Element.hide('comment_action')
		Element.show('add_comment')
	},

	cancel: function() {
		Element.show('comment_action')
		Element.hide('add_comment')
	}
}
