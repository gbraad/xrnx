--[[----------------------------------------------------------------------------
-- Duplex.Application
----------------------------------------------------------------------------]]--

--[[

A generic application class for Duplex
- extend this class to build applications for the Duplex Browser
- provides globally accessible configuration options 
- o start/stop applications
- o edit control-map groups, change built-in options 
- o browser integration: control autorun, aliases, pinned status
- 


--]]


--==============================================================================

class 'Application'

-- constructor 
function Application:__init()
  TRACE("Application:__init()")
  
  -- the application is considered created 
  -- once build_app() has been called
  self.created = false

  -- when the application is inactive, it should 
  -- sleep during idle time and ignore any user input
  self.active = false

  -- mappings allows us to choose where to put controls,
  -- see actual application implementations for examples
  -- 
  -- @group_name: the control-map group-name
  -- @required: you have to specify a group name
  -- @index: when nil, mapping is considered "greedy",
  -- and will use the entire group
  -- 
  -- example_mapping = {
  --  group_name = "Main",
  --  required = true,
  --  index = nil
  -- }
  self.mappings = {}

  -- you can choose to expose your application's options here
  -- the values can be edited using the options dialog
  -- 
  -- example_option = {
  --  label = "My option",
  --  items = {"Choice 1", "Choice 2"},
  --  default = 1 -- this is the default value ("Choice 1")
  -- }
  self.options = {}

  -- define a palette to enable color-picker support
  self.palette = {}

  -- the options dialog
  self.dialog = nil

  -- internal stuff
  self.view = nil
  self.vb = renoise.ViewBuilder()

end


--------------------------------------------------------------------------------

-- (run once) create view and members

function Application:build_app()
  TRACE("Application:build_app()")
  
  --local vb = renoise.ViewBuilder()
--[[  
  self.view = self.vb:text {
    text = "this is a blank application",
  }
]]  
  self.created = true
end


--------------------------------------------------------------------------------

-- start/resume application

function Application:start_app()
  TRACE("Application:start_app()")
  
  if not (self.created) then 
    return 
  end

  if (self.active) then
    return
  end

  self.active = true
end


--------------------------------------------------------------------------------

-- stop application

function Application:stop_app()
  TRACE("Application:stop_app()")
  
  if not (self.created) then 
    return 
  end

  if (not self.active) then
    return
  end

  self.active = false
end


--------------------------------------------------------------------------------

-- display application options

function Application:show_app()
  TRACE("Application:show_app()")
  
  if (not self.dialog) or (not self.dialog.visible) then
    self:__create_dialog()
  else
    self.dialog:show()
  end
end


--------------------------------------------------------------------------------

-- hide application options

function Application:hide_app()
  TRACE("Application:hide_app()")
  
  if (self.dialog) and (self.dialog.visible) then
    self.dialog:close()
    self.dialog = nil
  end

end


--------------------------------------------------------------------------------

-- destroy application

function Application:destroy_app()
  TRACE("Application:destroy_app()")
  self:hide_app()
  self:stop_app()
end


--------------------------------------------------------------------------------

-- handle periodic updates (many times per second)
-- nothing is done by default

function Application:idle_app()
  --[[
  -- it's a good idea to include this check 
  -- when doing complex stuff:
  if (not self.active) then 
    return 
  end
  ]]


end


--------------------------------------------------------------------------------

-- assign matching group-names

function Application:apply_mappings(mappings)

  for v,k in pairs(self.mappings) do
    for v2,k2 in pairs(mappings) do
      if (v==v2) then
        self.mappings[v].group_name = mappings[v].group_name
        self.mappings[v].index = mappings[v].index
      end
    end
  end

end


--------------------------------------------------------------------------------

-- todo: assign matching options

function Application:apply_options(options)

--[[
  for v,k in pairs(self.options) do

    for v2,k2 in pairs(options) do

  self.options.play_mode.value = options.play_mode.value
  self.options.switch_mode.value = options.switch_mode.value
  self.options.out_of_bounds.value = options.out_of_bounds.value
      if (v==v2) then

        self.options[v].value = options[v].value

      end

    end

  end

]]

end

--------------------------------------------------------------------------------

-- called when a new document becomes available

function Application:on_new_document()
  -- nothing done by default
end


--------------------------------------------------------------------------------

function Application:__create_dialog()
  TRACE("Application:__create_dialog()")
  
  self.dialog = renoise.app():show_custom_dialog(
    type(self), self.view
  )
end

--------------------------------------------------------------------------------

-- set options to default values (only locally)
-- @skip_update : don't update the dialog 
--  todo: remove the skip_update argument when we get a proper way to check 
--  if .views is defined

function Application:__set_default_options(skip_update)
  TRACE("Application:__set_default_options()")

  -- set local value
  for k,v in pairs(self.options) do
    self.options[k].value = self.options[k].default

    if(not skip_update)then
      local elm = self.vb.views[("dpx_app_options_%s"):format(k)]
      if(elm)then
        if(type(elm.value)=="boolean")then -- checkbox
          elm.value = self.options[k].items[self.options[k].default]
        else -- popup
          elm.value = self.options[k].default
        end
      end
    end

  end



end

--------------------------------------------------------------------------------

-- set option value 

function Application:__set_option(name,value)

  -- set local value
  for k,v in pairs(self.options) do
    if (k==name) then
      self.options[k].value = value
    end
  end
end


--------------------------------------------------------------------------------

function Application:__tostring()
  return type(self)
end  


--------------------------------------------------------------------------------

function Application:__eq(other)
  -- only check for object identity
  return rawequal(self, other)
end  


--------------------------------------------------------------------------------

-- create application options dialog

function Application:build_options()

  if (self.view)then
    return
  end

  -- create basic dialog 
  self.view = self.vb:column{
    id = 'dpx_app_rootnode',
    margin = DEFAULT_MARGIN,
    spacing = DEFAULT_MARGIN,
    style = "body",
    width=400,
    self.vb:column{
      style = "group",
      width="100%",
      self.vb:column{
        margin = DEFAULT_MARGIN,
        spacing = DEFAULT_SPACING,
        id = "dpx_app_mappings",
        self.vb:row{
          self.vb:text{
            id="dpx_app_mappings_header",
            font="bold",
            text="",
          },
        },
        -- mappings are inserted here
      },
      self.vb:space{
        width=18,
      },
    },
    self.vb:column{
      style = "group",
      width="100%",
      margin = DEFAULT_MARGIN,
      spacing = DEFAULT_SPACING,
      id = "dpx_app_options",
      self.vb:text{
        id="dpx_app_options_header",
        font="bold",
        text="",
      },
      -- options are inserted here
    },

    self.vb:horizontal_aligner{
      mode = "justify",

      self.vb:row{
        self.vb:button{
          text="Reset",
          width=60,
          height=24,
          notifier = function(e)
            self:__set_default_options()
          end
        },
        self.vb:button{
          text="Close",
          width=60,
          height=24,
          notifier = function(e)
            self:hide_app()
          end
        },
      }
    }
  }
  
  -- populate view with data
  local elm_group,elm_header

  -- mappings
  elm_group = self.vb.views.dpx_app_mappings
  elm_header = self.vb.views.dpx_app_mappings_header

  if (self.mappings) then
    -- update header text
    if (table_count(self.mappings)>0) then
      elm_header.text = "Control-map assignments"
    else
      elm_header.text = "No mappings are available"
    end
    -- build rows (required comes first)
    for k,v in pairs(self.mappings) do
      if(v.required)then 
        elm_group:add_child(self:__add_mapping_row(v,k))
      end
    end
    for k,v in pairs(self.mappings) do
      if(not v.required)then 
        elm_group:add_child(self:__add_mapping_row(v,k))
      end
    end
  end

  -- options
  elm_group = self.vb.views.dpx_app_options
  elm_header = self.vb.views.dpx_app_options_header
  if (self.options)then
    -- update header text
    if (table_count(self.options)>0) then
      elm_header.text = "Other options"
    else
      elm_header.text = "No options are available"
    end
    -- build rows (popups)
    for k,v in pairs(self.options) do
      if (v.items) and (type(v.items[1])~="boolean") then
        elm_group:add_child(self:__add_option_row(v,k))
      end
    end
    -- build rows (checkbox)
    for k,v in pairs(self.options) do
      if (v.items) and (type(v.items[1])=="boolean") then
        elm_group:add_child(self:__add_option_row(v,k))
      end
    end
  end
end


--------------------------------------------------------------------------------

-- build a row of mapping controls
-- @return ViewBuilder view

function Application:__add_mapping_row(t,key)

  local elm
  local row = self.vb:row{}

  -- leave out checkbox for required maps
  if(t.required)then 
    elm = self.vb:space{
      width=18,
    }
  else
    elm = self.vb:checkbox{
      value=(t.group_name~=nil),
      tooltip="Set this assignment as active/inactive",
      width=18,
    }
  end
  row:add_child(elm)
  elm = self.vb:row{
    self.vb:text{
      text=key,
      tooltip=("Assignment description: %s"):format(t.description),
      width=70,
    },
    self.vb:row{
      style="border",
      self.vb:text{
        text=t.group_name,
        tooltip="The selected control-map group",
        font="mono",
        width=110,
      },
      self.vb:button{
        text="Choose",
        tooltip="Click here to choose a control-map group for this assignment",
        width=60,
        notifier = function()
          renoise.app():show_warning("Mapping dialog not yet implemented")
        end
      }
    }
  }
  row:add_child(elm)
  return row

end

--------------------------------------------------------------------------------

-- build a row of option controls
-- @return ViewBuilder view

function Application:__add_option_row(t,key)

  local elm
  local row = self.vb:row{}

  if (t.items) and (type(t.items[1])=="boolean") then
    -- boolean option
    elm = self.vb:row{
      self.vb:checkbox{
        value=t.items[t.value],
        id=('dpx_app_options_%s'):format(key),
        width=18,
        --id = checkbox_id,
        notifier = function(val)
          self:__set_option(key,val)
        end
      },
      self.vb:text{
        text=t.label,
        tooltip=t.description,
      },
    }
  
  else
    -- choice
      elm = self.vb:row{
        self.vb:text{
          text=t.label,
          --tooltip=t.label,
          width=90,
        },
        self.vb:popup{
          items=t.items,
          id=('dpx_app_options_%s'):format(key),
          value=t.value,
          width=160,
          notifier = function(val)
            self:__set_option(key,val)
          end
        }
      }
  end

  row:add_child(elm)

  return row
end