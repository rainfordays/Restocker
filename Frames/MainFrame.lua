local _, core = ...;


core.hiddenFrame = CreateFrame("Frame", nil, UIParent)
core.hiddenFrame:Hide()

function core:CreateMenu()
  --[[
    FRAME
  ]]

  local addon = CreateFrame("Frame", "RestockerMainFrame", UIParent, "BasicFrameTemplate");
  addon.width = 300
  addon.height = 400
  addon:SetSize(addon.width, addon.height);
  addon:SetPoint(Restocker.framePos.point or "RIGHT", UIParent, Restocker.framePos.relativePoint or "RIGHT", Restocker.framePos.xOfs or -5, Restocker.framePos.yOfs or 0);
  addon:SetFrameStrata("FULLSCREEN");
  addon:SetMovable(true)
  addon:EnableMouse(true)
  addon:RegisterForDrag("LeftButton")
  addon:SetScript("OnDragStart", addon.StartMoving)
  addon:SetScript("OnDragStop", addon.StopMovingOrSizing)

  --[[
    INSET
  ]]
  local listInset = CreateFrame("Frame", nil, addon, "InsetFrameTemplate3");
  listInset.width = addon.width - 6
  listInset.height = addon.height - 76
  listInset:SetSize(listInset.width, listInset.height);
  listInset:SetPoint("TOPLEFT", addon, "TOPLEFT", 2, -22);
  addon.listInset = listInset

  --[[
    SCROLL FRAME
  ]]
  local scrollFrame = CreateFrame("ScrollFrame", nil, addon, "UIPanelScrollFrameTemplate")
  scrollFrame.width = addon.listInset.width - 4
  scrollFrame.height = addon.listInset.height - 32
  scrollFrame:SetSize(scrollFrame.width-30, scrollFrame.height);
  scrollFrame:SetPoint("TOPLEFT", listInset, "TOPLEFT", 8, -6);
  addon.scrollFrame = scrollFrame

  --[[
    SCROLL CHILD
  ]]
  local scrollChild = CreateFrame("Frame",nil,ScrollFrame)
  scrollChild.width = scrollFrame:GetWidth()
  scrollChild.height = scrollFrame:GetHeight()
  scrollChild:SetWidth(scrollChild.width)
  scrollChild:SetHeight(scrollChild.height-10)
  addon.scrollChild = scrollChild

  scrollFrame:SetScrollChild(scrollChild)






  --[[
    TITLE
  ]]
  local title = addon:CreateFontString(nil, "OVERLAY");
  title:SetFontObject("GameFontHighlightLarge");
  title:SetPoint("CENTER", addon.TitleBg, "CENTER", 0, 0);
  title:SetText("Restocker");
  addon.title = title


  --[[
    EDITBOX & ADD BUTTON GROUP
  ]]
  local addGrp = CreateFrame("Frame", nil, addon);
  addGrp:SetPoint("BOTTOM", addon.listInset, "BOTTOM", 0, 2);
  addGrp:SetSize(listInset.width-5, 25);
  addon.addGrp = addGrp




    -- Add button
    local addBtn = CreateFrame("Button", nil, addon.addGrp, "GameMenuButtonTemplate");
    addBtn:SetPoint("BOTTOMRIGHT", addon.addGrp, "BOTTOMRIGHT");
    addBtn:SetSize(60, 25);
    addBtn:SetText("Add");
    addBtn:SetNormalFontObject("GameFontNormal");
    addBtn:SetHighlightFontObject("GameFontHighlight");
    addBtn:SetScript("OnClick", function(self, button, down)
      local editBox = self:GetParent():GetParent().editBox
      local text = editBox:GetText()

      core:addItem(text);

      editBox:SetText("")
      editBox:ClearFocus()
    end);


    -- Text field
    local editBox = CreateFrame("EditBox", nil, addon.addGrp, "InputBoxTemplate");
    editBox:SetPoint("RIGHT", addBtn, "LEFT", 3);
    editBox:SetAutoFocus(false);
    editBox:SetSize(addon.addGrp:GetWidth()-addBtn:GetWidth()-5, 25);
    editBox:SetScript("OnEnterPressed", function(self)
      local text = self:GetText()

      core:addItem(text)

      self:SetText("")
      self:ClearFocus()

    end)
    editBox:SetScript("OnMouseUp", function(self, button)
      if button == "LeftButton" then
        infoType, info1 = GetCursorInfo()
        if infoType == "item" then
          itemName = GetItemInfo(info1)
          core:addItem(text)
          ClearCursor()
        end
      end
    end)
    editBox:SetScript("OnReceiveDrag", function(self)
      infoType, info1 = GetCursorInfo()
      if infoType == "item" then
        itemName = GetItemInfo(info1)
        core:addItem(text)
        ClearCursor()
      end
    end)

    addon.editBox = editBox
    addon.addBtn = addBtn

  -- END OF GROUP



  --[[
    AUTOBUY CHECKBOX
  ]]

  -- Checkbox for autobuy
    local checkbox = CreateFrame("CheckButton", nil, addon, "UICheckButtonTemplate");
    checkbox:SetPoint("TOPLEFT", addon.listInset, "BOTTOMLEFT", 2, -2)
    checkbox:SetSize(25, 25)
    checkbox:SetChecked(Restocker.autoBuy);
    checkbox:SetScript("OnClick", function(self, button, down)
      Restocker.autoBuy = checkbox:GetChecked()
    end);
    addon.checkbox = checkbox

    -- Auto buy text
    local checkboxText = addon:CreateFontString(nil, "OVERLAY");
    checkboxText:SetFontObject("GameFontHighlight");
    checkboxText:SetPoint("LEFT", checkbox, "RIGHT", 1, 1);
    checkboxText:SetText("Auto buy items");
    addon.checkbox = checkboxText
  -- // AUTOBUY



  --[[
    PROFILES
  ]]
  local profileText = addon:CreateFontString(nil, "OVERLAY")
  profileText:SetPoint("BOTTOMLEFT", addon, "BOTTOMLEFT", 10, 12)
  profileText:SetFontObject("GameFontNormal")
  profileText:SetText("Profile:")


  local Restocker_ProfileDropDownMenu = CreateFrame("Frame", "Restocker_ProfileDropDownMenu", addon, "UIDropDownMenuTemplate")
  Restocker_ProfileDropDownMenu:SetPoint("LEFT", profileText, "LEFT", 80, 0)
  --Restocker_ProfileDropDownMenu.displayMode = "MENU"
  UIDropDownMenu_SetWidth(Restocker_ProfileDropDownMenu, 120, 500)
  UIDropDownMenu_SetButtonWidth(Restocker_ProfileDropDownMenu, 140)
  UIDropDownMenu_SetText(Restocker_ProfileDropDownMenu, Restocker.currentProfile)

  Restocker_ProfileDropDownMenu.initialize = function(self, level)
    if not level then return end

    for profileName, _ in pairs(Restocker.profiles) do
      local info = UIDropDownMenu_CreateInfo()

      info.text = profileName
      info.arg1 = profileName
      info.func = core.DropDownMenuSelectProfile
      info.checked = profileName == Restocker.currentProfile

      UIDropDownMenu_AddButton(info, 1)
    end
  end

  addon.profileDropDownMenu = Restocker_ProfileDropDownMenu


  tinsert(UISpecialFrames, "RestockerMainFrame")
  addon:Hide()

  core.addon = addon
  return core.addon
end


-- Handle shiftclicks of items
local origChatEdit_InsertLink = ChatEdit_InsertLink;
ChatEdit_InsertLink = function(link)
  if core.addon.editBox:IsVisible() and core.addon.editBox:HasFocus() then
    --itemName = GetItemInfo(link)
    core:addItem(link)
    return true
  end
  return origChatEdit_InsertLink(link);
end


function core.DropDownMenuSelectProfile(self, arg1, arg2, checked)
  core:ChangeProfile(arg1)
end




function core:addItem(text)
  local currentProfile = Restocker.profiles[Restocker.currentProfile]


  if string.find(text, "%d") and not string.find(text, "Hitem") then text = tonumber(text) end

  local itemName, itemLink = GetItemInfo(text)
  local itemID
  if itemLink == nil then
    core.itemWaitTable[text] = true
    return
  elseif itemLink ~= nil then
    itemID = string.match(itemLink, "item:(%d+)")
    for _, item in ipairs(currentProfile) do
      if item.itemName:lower() == itemName:lower() then return end
    end
  end

  local T = {}

  T.itemName = itemName
  T.itemLink = itemLink
  T.itemID = itemID
  T.amount = 1
  tinsert(Restocker.profiles[Restocker.currentProfile], T)

  core:Update()
end
