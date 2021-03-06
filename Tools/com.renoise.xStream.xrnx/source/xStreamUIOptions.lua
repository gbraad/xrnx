--[[============================================================================
xStreamUIOptions
============================================================================]]--
--[[

	Supporting class for xStream 

]]

--==============================================================================

class 'xStreamUIOptions' (vDialog)

xStreamUIOptions.DLG_W = 130
xStreamUIOptions.TXT_W = 70

local TABLE_W = 145
local TABLE_ROW_H = 19
local MIDI_ROWS = 5

-------------------------------------------------------------------------------

function xStreamUIOptions:__init(xstream)
  TRACE("xStreamUIOptions:__init(xstream)",xstream)

  assert(type(xstream)=="xStream","Expected 'xstream' as argument")

  self.xstream = xstream

  self.prefs = renoise.tool().preferences

  vDialog.__init(self)

  self.title = "xStream options"

  self.update_model_requested = false

  self.selected_tab_index = 1

  -- vLib components
  self.vtable_midi_inputs = nil
  self.vtable_midi_outputs = nil

  -- initialize

  renoise.tool().app_idle_observable:add_notifier(function()
    self:on_idle()
  end)

  self.xstream.selected_model_index_observable:add_notifier(function()    
    if self.prefs.launch_selected_model.value then
      --print(">>> self.xstream.selected_model_index",self.xstream.selected_model_index)
      if (self.xstream.selected_model_index > 0) then
        local model = self.xstream.models[self.xstream.selected_model_index]
        self.prefs.launch_model.value = model.file_path
        --print("model.file_path",model,model.file_path)
      end
      self.update_model_requested = true
    end
  end)

  self.prefs.launch_selected_model:add_notifier(function()
    self.update_model_requested = true
  end)

  self.xstream.models_observable:add_notifier(function()
    self.update_model_requested = true
  end)

  self:show_tab(self.selected_tab_index)

  -- prevent device editing while inactive
  self.xstream.active_observable:add_notifier(function()
    if self.vtable_midi_inputs then
      self.vtable_midi_inputs.active = self.xstream.active
    end
    if self.vtable_midi_outputs then
      self.vtable_midi_outputs.active = self.xstream.active
    end
  end)

end

-------------------------------------------------------------------------------
-- Overridden methods
-------------------------------------------------------------------------------

function xStreamUIOptions:show()

  vDialog.show(self)

  self.update_model_requested = true
  self:show_tab(self.selected_tab_index)

end

--------------------------------------------------------------------------------
-- Class methods
--------------------------------------------------------------------------------

function xStreamUIOptions:show_tab(idx)
  TRACE("xStreamUIOptions:show_tab(idx)",idx)

  local tabs = {
    "xStreamOptionsGeneral",
    "xStreamOptionsStreaming",
    "xStreamOptionsMIDI",
    "xStreamOptionsOutput",
  }

  for k,v in ipairs(tabs) do
    local tab_elm = self.vb.views[v]
    if tab_elm then
      self.vb.views[v].visible = false
    end
  end

  local tab_elm = self.vb.views[tabs[idx]]
  if tab_elm then
    tab_elm.visible = true
  end

  self.selected_tab_index = idx

end

-------------------------------------------------------------------------------

function xStreamUIOptions:create_dialog()

  self.xstream.stream.writeahead_factor_observable:add_notifier(function()
    TRACE("*** xStreamUI - self.xstream.stream.writeahead_factor_observable fired...",self.xstream.stream.writeahead_factor)
    local view = self.vb.views["xStreamImplWriteAheadFactor"]
    view.value = self.xstream.stream.writeahead_factor
  end)

  local STREAMING_TXT_W = 120
  local STREAMING_CTRL_W = 100

  local vb = self.vb
  local vb_tab_content = vb:column{ -- options 
    margin = 6,
    vb:switch{
      id = "xStreamOptionsTab",
      value = self.selected_tab_index,
      items = {
        "General",
        "Streaming",
        "MIDI",
        "Output",
      },
      width = 300,
      notifier = function(idx)
        self:show_tab(idx)
      end
    },
    vb:space{
      height = 6,
    },

    -- GENERAL OPTIONS ----------------------------------

    vb:column{
      id = "xStreamOptionsGeneral",
      width = "100%",
      visible = false,
      spacing = 6,
      vb:column{
        --style = "group",
        width = "100%",
        --margin = 6,
        vb:row{
          vb:checkbox{
            bind = self.prefs.autostart,
          },
          vb:text{
            text="Autostart tool when Renoise launches",
          },
        },
        vb:row{
          vb:checkbox{            
            bind = self.prefs.launch_selected_model,
          },
          vb:text{
            text= "Remember selected model, or choose"
          },
          vb:popup{
            items = {xStreamUI.NO_MODEL_SELECTED},
            id = "xStreamImplLaunchModel",
            notifier = function(idx)
              local model = self.xstream.models[idx-1]
              if model then
                self.prefs.launch_model.value = model.file_path
              end
            end,
          },
        },
        vb:row{
          vb:text{
            text= "Userdata"
          },
          vb:textfield{
            width = 160,
            bind = self.prefs.user_folder,
          },
          vb:button{
            text = "Browse",
            notifier = function()
              local new_path = renoise.app():prompt_for_path("Specify folder for models, preset and favorites")
              if (new_path ~= "") then
                self.prefs.user_folder.value = new_path
              end
            end,
          },
          vb:button{
            text = "Reset",
            notifier = function()
              self.prefs.user_folder.value = xStreamPrefs.USER_FOLDER
            end,
          }        
        },
        --[[
        vb:button{
          text = "remove trace statements",
          notifier = function()
            cDebug.remove_trace_statements()
          end
        }
        ]]

      },
      vb:column{ -- stats
        margin = 4,
        width = "100%",
        style = "group",
        vb:text{
          text= "Stats",
          font = "bold",
        },
        vb:text{
          text= "",
          id = "xStreamImplStats",
        },
      },
    },
    
    -- STREAMING OPTIONS ----------------------------------

    vb:column{
      id = "xStreamOptionsStreaming",
      visible = false,
      spacing = 6,
      --style = "group",
      width = "100%",
      vb:row{
        vb:checkbox{
          id = "xStreamImplSuspend",
          bind = self.prefs.suspend_when_hidden,
        },
        vb:text{
          text="Suspend streaming while interface is hidden",
        },
      },

      vb:column{
        margin = 6,
        style = "group",
        width = "100%",
        vb:row{
          vb:text{
            text="Enable streaming",
            width = STREAMING_TXT_W,
          },
          vb:row{
            vb:popup{
              bind = self.prefs.start_option,
              items = xStreamPrefs.START_OPTIONS,
              width = STREAMING_CTRL_W,
            },
          },
        },

        vb:row{
          vb:text{
            text = "Default scheduling",
            width = STREAMING_TXT_W,
          },
          vb:popup{
            items = xStream.SCHEDULES,
            bind = self.prefs.scheduling,
            width = STREAMING_CTRL_W,
          },
        },

        vb:row{
          vb:text{
            text = "Stream mute-mode",
            width = STREAMING_TXT_W,
          },
          vb:popup{
            items = xStream.MUTE_MODES,
            bind = self.xstream.mute_mode_observable,
            width = STREAMING_CTRL_W,
          },
        },

        vb:row{
          tooltip = "Control how far ahead xStream should produce output (smaller = longer)",
          vb:text{
            text="Writeahead factor",
            width = STREAMING_TXT_W,
          },
          vb:valuebox{
            id = "xStreamImplWriteAheadFactor",
            min = 125,
            max = 400,
            width = STREAMING_CTRL_W,
            value = self.xstream.stream.writeahead_factor,
            notifier = function(val)
              self.xstream.stream.writeahead_factor = val
            end
          },
        },


      },

    },

    -- MIDI OPTIONS ----------------------------------

    vb:column{
      id = "xStreamOptionsMIDI",
      width = "100%",
      visible = false,
      spacing = 6,
      vb:row{
        spacing = 6,
        vb:column{
          --margin = 6,
          id = "xStreamPrefsMidiInputRack",
          vb:text{
            text = "MIDI Inputs",
            font = "bold",
          },
        },
        vb:column{
          --margin = 6,
          id = "xStreamPrefsMidiOutputRack",
          vb:text{
            text = "MIDI Outputs",
            font = "bold",
          },
          
        },
      },

      vb:column{
        style = "group",
        margin = 6,
        width = "100%",
        vb:text{
          text = "Internal routing (OSC server)",
          font = "bold",
        },
        vb:row{
          vb:text{
            text = "IP/address",
            --width = OSC_LABEL_W,
          },
          vb:textfield{
            value = self.xstream.osc_client.osc_host,
            --width = OSC_CONTROL_W,
            notifier = function(val)
              -- TODO check if valid 'address'
              self.xstream.osc_client.osc_host = val
            end,
          },
          vb:text{
            text = "→ default is 127.0.0.1",
            --width = OSC_LABEL_W,
          },
        },
        vb:row{
          vb:text{
            text = "Port number",
            --width = OSC_LABEL_W,
          },
          vb:valuebox{
            value = self.xstream.osc_client.osc_port,
            --width = OSC_CONTROL_W,
            min = 0,
            max = 65535,
            notifier = function(val)
              self.xstream.osc_client.osc_port = val
            end,
          },
          vb:text{
            text = "→ same as Renoise OSC prefs!",
            --width = OSC_LABEL_W,
          },
        },
      },

      vb:column{
        style = "group",
        margin = 6,
        width = "100%",
        vb:row{
          vb:checkbox{
            value = self.prefs.midi_multibyte_enabled.value,
            notifier = function(val)
              self.prefs.midi_multibyte_enabled.value = val
            end,
          },
          vb:text{
            text = "Enable multi-byte support (14bit control-change)"
          },
        },
        vb:row{
          vb:checkbox{
            value = self.prefs.midi_nrpn_enabled.value,
            notifier = function(val)
              self.prefs.midi_nrpn_enabled.value = val
            end,
          },
          vb:text{
            text = "Enable NRPN support (14bit messages)"
          },
        },
        vb:row{
          vb:checkbox{
            value = self.prefs.midi_terminate_nrpns.value,
            notifier = function(val)
              self.prefs.midi_terminate_nrpns.value = val
            end,
          },
          vb:text{
            text = "Require NRPN messages to be terminated"
          },
        },
      },

    },


    -- OUTPUT OPTIONS ----------------------------------

    vb:column{ -- panel
      id = "xStreamOptionsOutput",
      visible = false,
      width = "100%",
      vb:column{
        vb:text{
          text =  "These settings are provided as default values - each model"
                .."\ncan choose to override the values with it's own ones.",
        },
        vb:space{
          height = 6,
        }
      },
      vb:column{ 
        margin = 6,
        style = "group",
        width = "100%",
        --[[
        vb:row{
          tooltip = "The active track at which xStream will produce output",
          vb:text{
            text = "track_index",
          },
          vb:valuebox{
            min = 0,
            max = 255,
            bind = self.xstream.track_index_observable,
          },
        },
        vb:row{
          tooltip = "The automation device-parameter where automation is written",
          vb:text{
            text = "param_index",
          },
          vb:valuebox{
            min = 0,
            max = 255,
            bind = self.xstream.device_param_index_observable,
          },
        },
        ]]

        vb:row{
          tooltip = "Determine the default automation interpolation/playmode",
          vb:text{
            text = "Automation playmode",
          },
          vb:popup{
            items = xStream.PLAYMODES,
            bind = self.xstream.automation_playmode_observable,
          },
        },

        vb:row{
          tooltip = "Whether to include hidden columns when writing output",
          vb:checkbox{
            bind = self.xstream.include_hidden_observable,
          },
          vb:text{
            text = "include_hidden",
          },
        },
        vb:row{
          tooltip = "Whether to clear undefined values, columns",
          vb:checkbox{
            bind = self.xstream.clear_undefined_observable,
          },
          vb:text{
            text = "clear_undefined",
          },
        },
        vb:row{
          tooltip = "Automatically reveal (sub-)columns with output",
          vb:checkbox{
            bind = self.xstream.expand_columns_observable,
          },
          vb:text{
            text = "expand_columns",
          },
        },
      },

    },

  }

  local toggle_midi_input = function(elm,checked)
    --print("toggle_midi_input",elm,checked)
    local item = elm.owner:get_item_by_id(elm.item_id)
    if item then
      item.CHECKBOX = checked
      local matched = self:match_in_list(self.prefs.midi_inputs,item.TEXT)
      if checked and not matched then
        --self.prefs.midi_inputs:insert(item.TEXT)
        self.xstream.midi_io:open_midi_input(item.TEXT)
      elseif not checked and matched then
        --self.prefs.midi_inputs:remove(matched)
        self.xstream.midi_io:close_midi_input(item.TEXT)
      end
    end
  end

  local vtable = vTable{
    id = "vtable_midi_inputs",
    vb = vb,
    width = TABLE_W,
    row_height = TABLE_ROW_H,
    num_rows = MIDI_ROWS,
    column_defs = {
      {key = "CHECKBOX", col_width=20, col_type=vTable.CELLTYPE.CHECKBOX, notifier=toggle_midi_input},
      {key = "TEXT",    col_width="auto"},
    },
    data = {},
  }
  --print("vtable",vtable)
  vb.views["xStreamPrefsMidiInputRack"]:add_child(vtable.view)
  self.vtable_midi_inputs = vtable

  -- midi outputs --

  local toggle_midi_output = function(elm,checked)
    local item = elm.owner:get_item_by_id(elm.item_id)
    if item then
      item.CHECKBOX = checked
      local matched = self:match_in_list(self.prefs.midi_outputs,item.TEXT)
      if checked and not matched then
        self.prefs.midi_outputs:insert(item.TEXT)
        --self.xstream:open_midi_output(item.TEXT)
      elseif not checked and matched then
        self.prefs.midi_outputs:remove(matched)
        --self.xstream:close_midi_output(item.TEXT)
      end
    end
  end

  vtable = vTable{
    id = "vtable_midi_outputs",
    vb = vb,
    width = TABLE_W,
    row_height = TABLE_ROW_H,
    num_rows = MIDI_ROWS,
    column_defs = {
      {key = "CHECKBOX", col_width=20, col_type=vTable.CELLTYPE.CHECKBOX, notifier=toggle_midi_output},
      {key = "TEXT",    col_width="auto"},
    },
    data = {},
  }
  vb.views["xStreamPrefsMidiOutputRack"]:add_child(vtable.view)
  self.vtable_midi_outputs = vtable

  self:update_input_tab()

  return vb_tab_content

end

--------------------------------------------------------------------------------

function xStreamUIOptions:update_model_selector(model_names)
  TRACE("xStreamUIOptions:update_model_selector(model_names)",model_names)

  local model_popup = self.vb.views["xStreamImplLaunchModel"]
  if model_popup then
    local model_names = self.xstream:get_model_names(true)
    table.insert(model_names,1,xStreamUI.NO_MODEL_SELECTED)
    model_popup.items = model_names
    model_popup.active = not self.prefs.launch_selected_model.value
    if self.prefs.launch_selected_model.value then
      model_popup.value = (self.xstream.selected_model_index == 0) 
        and 1 or self.xstream.selected_model_index+1
    else
      for k,v in ipairs(self.xstream.models) do
        if (v.file_path == self.xstream.launch_model) then
          model_popup.value = k
        end
      end
    end
  end
end

--------------------------------------------------------------------------------

function xStreamUIOptions:on_idle()
  
  if self.update_model_requested then
    self.update_model_requested = false
    self:update_model_selector()
  end

  -- display some stats 
  local xs = self.xstream 
  local view = self.vb.views["xStreamImplStats"]
  if view then
    local str_stat = ("Memory usage: %.2f Mb"):format(collectgarbage("count")/1024)
      ..("\nLines Travelled: %d"):format(xs.stream.writepos.lines_travelled)
      ..("\nReadPosition: %d,%d"):format(xs.stream.readpos.sequence,xs.stream.readpos.line)
      ..("\nWritePosition: %d,%d"):format(xs.stream.writepos.sequence,xs.stream.writepos.line)
      ..("\nWriteahead: %d lines"):format(xs.stream.writeahead)
      ..("\nSelected model: %s"):format(xs.selected_model and xs.selected_model.name or "N/A") 
      ..("\nStream active: %s"):format(xs.active and "true" or "false") 
      ..("\nStream muted: %s"):format(xs.muted and "true" or "false") 
    view.text = str_stat
  end

end

--------------------------------------------------------------------------------

function xStreamUIOptions:update_input_tab()

  -- midi inputs --

  local midi_inputs = renoise.Midi.available_input_devices()
  local midi_outputs = renoise.Midi.available_output_devices()
  local data,vtable

  data = {}
  vtable = self.vtable_midi_inputs
  for k,v in ipairs(midi_inputs) do
    data[k] = {
      CHECKBOX = (self:match_in_list(self.prefs.midi_inputs,v)) and true or false,
      TEXT = v,
    }
  end
  --rprint("midi_inputs data",rprint(data))
  vtable.data = data
  vtable.show_header = false
  vtable:update()

  -- midi outputs --

  data = {}
  vtable = self.vtable_midi_outputs
  for k,v in ipairs(midi_inputs) do
    data[k] = {
      CHECKBOX = (self:match_in_list(self.prefs.midi_outputs,v)) and true or false,
      TEXT = v,
    }
  end
  vtable.data = data
  vtable.show_header = false
  vtable:update()

end


-------------------------------------------------------------------------------
-- find among midi inputs/outputs
-- @param list (table)
-- @param value (string)
-- @return int or nil

function xStreamUIOptions:match_in_list(list,value)

  local matched = false
  for k = 1, #list do
    if (list[k].value == value) then
      return k
    end
  end

end

