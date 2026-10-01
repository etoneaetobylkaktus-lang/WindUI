local Creator = require("../modules/Creator")
local New = Creator.New
local CreateButton = require("../components/ui/Button").New

local Players = game:GetService("Players")
local GuiService = game:GetService("GuiService")

local Element = {}

local function DecodeEntities(value)

 value = value:gsub("&amp;", "&"):gsub("&quot;", '"'):gsub("&#39;", "'")
 value = value:gsub("&lt;", "<"):gsub("&gt;", ">")
 value = value:gsub("&#(%d+);", function(code)
  local point = tonumber(code)
  if point and point > 0 and point <= 0x10FFFF and not (point >= 0xD800 and point <= 0xDFFF) then
   return utf8.char(point)
  end
  return ""
 end)
 return value
end

local function ReadMeta(html, key)
 local escaped = key:gsub("([^%w])", "%%%1")
 local value = html:match('<meta property="' .. escaped .. '" content="(.-)"')
  or html:match("<meta property='" .. escaped .. "' content='(.-)'")
  or html:match('<meta name="' .. escaped .. '" content="(.-)"')
 return value and DecodeEntities(value)
end

local function FormatCount(text)
 if not text then return nil end
 local compact = text:match("([%d%.%,]+%s*[KkMm]?)%s+subscribers?")
  or text:match("([%d%.%,]+%s*[KkMm]?)%s+members?")
 return compact and compact:gsub("%s+", "") or nil
end

function Element:New(Config)
	Config.Hover = false
	Config.TextOffset = 0
	Config.ParentConfig = Config
	Config.IsButtons = false

 local username = tostring(Config.ChannelUser or ""):gsub("^@", "")
 if #username < 5 or #username > 32 or not username:match("^[%w_]+$") then
  error("TelegramParagraph: ChannelUser must be a public Telegram channel username")
 end

 local url = "https://t.me/" .. username
 local Frame = require("../components/window/Element")(Config)
 local Card = {
  __type = "TelegramParagraph",
  Title = Config.Title or "Telegram",
  ChannelUser = username,
  URL = url,
  ParagraphFrame = Frame,
  UIElements = {},
 }

 local Row = New("Frame", {
  Name = "TelegramChannelInfo",
  Size = UDim2.new(1, 0, 0, 64),
  BackgroundTransparency = 1,
  Parent = Frame.UIElements.Container,
 }, {
  New("UIListLayout", {
   FillDirection = Enum.FillDirection.Horizontal,
   VerticalAlignment = Enum.VerticalAlignment.Center,
   Padding = UDim.new(0, 12),
  }),
 })

 local Avatar = Creator.Image("", username, 0, Config.Window.Folder, "TelegramAvatar", false)
 Avatar.Name = "ChannelAvatar"
 Avatar.Size = UDim2.fromOffset(52, 52)
 Avatar.LayoutOrder = 1
 Avatar.Parent = Row
 New("UICorner", { CornerRadius = UDim.new(1, 0), Parent = Avatar })

 local Info = New("Frame", {
  Name = "ChannelDetails",
  BackgroundTransparency = 1,
  Size = UDim2.new(1, -64, 1, 0),
  LayoutOrder = 2,
  Parent = Row,
 }, {
  New("UIListLayout", {
   FillDirection = Enum.FillDirection.Vertical,
   VerticalAlignment = Enum.VerticalAlignment.Center,
   Padding = UDim.new(0, 3),
  }),
 })

 local ChannelTitle = New("TextLabel", {
  Name = "ChannelTitle",
  Size = UDim2.new(1, 0, 0, 23),
  BackgroundTransparency = 1,
  Text = "Loading Telegram channel...",
  TextXAlignment = Enum.TextXAlignment.Left,
  TextTruncate = Enum.TextTruncate.AtEnd,
  TextSize = 16,
  Font = Enum.Font.GothamSemibold,
  ThemeTag = { TextColor3 = "Text" },
  Parent = Info,
 })

 local SubscriberCount = New("TextLabel", {
  Name = "SubscriberCount",
  Size = UDim2.new(1, 0, 0, 19),
  BackgroundTransparency = 1,
  Text = "@" .. username,
  TextXAlignment = Enum.TextXAlignment.Left,
  TextTruncate = Enum.TextTruncate.AtEnd,
  TextSize = 13,
  Font = Enum.Font.Gotham,
  TextTransparency = 0.2,
  ThemeTag = { TextColor3 = "Text" },
  Parent = Info,
 })

 local ButtonHolder = New("Frame", {
  Size = UDim2.new(1, 0, 0, 38),
  BackgroundTransparency = 1,
  Parent = Frame.UIElements.Container,
 })

 local function OpenChannel()
  local clipboard = setclipboard or toclipboard
  if clipboard then
   pcall(clipboard, url)
  end
  local opened = pcall(function()
   GuiService:OpenBrowserWindow(url)
  end)
  if not opened then
   pcall(function()
    GuiService:OpenUrl(url)
   end)
  end
 end

 local Button = CreateButton(
  Config.ButtonTitle or "Open Telegram Channel",
  Config.ButtonIcon or "send",
  OpenChannel,
  "White",
  ButtonHolder,
  nil,
  nil,
  Config.Window.NewElements and 999 or 10
 )
 Button.Size = UDim2.new(1, 0, 0, 38)

 function Card:Open()
  OpenChannel()
 end

 function Card:SetChannelUser(newUsername)
  newUsername = tostring(newUsername or ""):gsub("^@", "")
  if #newUsername < 5 or #newUsername > 32 or not newUsername:match("^[%w_]+$") then
   return false, "ChannelUser must be a public Telegram channel username"
  end
  username = newUsername
  Card.ChannelUser = username
  Card.URL = "https://t.me/" .. username
  Card:Refresh()
  return true
 end

 function Card:Refresh()
  ChannelTitle.Text = "Loading Telegram channel..."
  SubscriberCount.Text = "@" .. username

  task.spawn(function()
   local request = Creator.Request or request or http_request
   if not request then
    ChannelTitle.Text = "Telegram channel"
    SubscriberCount.Text = "Metadata unavailable in this environment"
    return
   end

   local success, response = pcall(function()
    return request({ Url = "https://t.me/s/" .. username, Method = "GET" })
   end)

   local html = success and type(response) == "table" and response.Body
   if type(html) ~= "string" or not html:find("telegram%.org") and not html:find("tgme_page") then
    ChannelTitle.Text = "Telegram channel not verified"
    SubscriberCount.Text = "Could not confirm a public channel at @" .. username
    return
   end

   local title = ReadMeta(html, "og:title")
    or html:match('class="tgme_page_title"[^>]*>[%s\n]*(.-)[%s\n]*</div>')
   local description = ReadMeta(html, "og:description") or ""
   local avatarUrl = ReadMeta(html, "og:image")
   local count = FormatCount(description)
    or FormatCount(html:match('class="tgme_page_extra"[^>]*>(.-)</div>'))

   if title then
    title = title:gsub("<[^>]->", "")
    ChannelTitle.Text = DecodeEntities(title)
    SubscriberCount.Text = count and (count .. " subscribers · @" .. username) or ("@" .. username)
    if avatarUrl then
     local avatar = Creator.Image(avatarUrl, username, 26, Config.Window.Folder, "TelegramAvatar", false)
     avatar.Name = "ChannelAvatar"
     avatar.Size = UDim2.fromOffset(52, 52)
     avatar.LayoutOrder = 1
     avatar.Parent = Row
     Avatar:Destroy()
     Avatar = avatar
    end
   else
    ChannelTitle.Text = "Telegram channel not found"
    SubscriberCount.Text = "No public channel matched @" .. username
   end
  end)
 end

 function Card:Destroy()
  Frame:Destroy()
 end

 Card:Refresh()
 return Card.__type, Card
end

return Element
