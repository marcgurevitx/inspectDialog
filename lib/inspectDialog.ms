import "stringUtil"
import "textUtil"

// InspectDialog: a Dialog subclass specialized for inspecting MiniScript values.
InspectDialog = new textUtil.Dialog
InspectDialog.width = 55
InspectDialog.contentHeight = 15
InspectDialog.backColor = "#140951"
InspectDialog.titleColor = "#1C4581"
InspectDialog.textColor = "#65B4A7"
InspectDialog.valueColor = "#F0FEDF"
InspectDialog.valueBackground = "#1C4581"
InspectDialog.valueInfo = null

InspectDialogValue = {}  // stack of values (if we deside to go inside lists/maps
InspectDialogValue.value = null
InspectDialogValue.parent = null
InspectDialogValue.type = null
InspectDialogValue.lines = null
InspectDialogValue.linesOffset = null
InspectDialogValue.linesBelowContent = null
InspectDialogValue.keyWidth = null
InspectDialogValue.sortedKeys = null
InspectDialogValue.kLines = null
InspectDialogValue.vLines = null
InspectDialogValue.cursor = null
InspectDialogValue.isAtKey = false
InspectDialogValue.init = function(value, dlog)
	self.value = @value
	self.type = InspectDialogValue.getTypeString(@value)
	if @value == null then
		self.initSimpleValue "null", dlog
	else if @value isa number then
		self.initSimpleValue str(value), dlog
	else if @value isa string then
		self.initSimpleValue value, dlog
	else if @value isa funcRef then
		self.initSimpleValue str(@value), dlog
	else if @value isa list then
		self.keyWidth = 5
		self.sortedKeys = value.indexes
		self.initContainerValue value, dlog
	else if @value isa map then
		self.keyWidth = (dlog.width - 4) / 2
		self.sortedKeys = value.indexes.sort
		self.initContainerValue value, dlog
	else
		self.initSimpleValue "value of unknown type", dlog
	end if
	return self
end function
InspectDialogValue.getTypeString = function(value)
	if @value == null then
		return "null"
	else if @value isa number then
		return "number"
	else if @value isa string then
		return "string(" + value.len + ")"
	else if @value isa funcRef then
		return "funcRef"
	else if @value isa list then
		return "list(" + value.len + ")"
	else if @value isa map then
		typeString = "map(" + value.len + ")"
		name = mapName(value)
		if name then typeString += " == " + name
		return typeString
	else
		return "unknown type"
	end if
end function
InspectDialogValue.initSimpleValue = function(text, dlog)
	self.lines = text.wrap(dlog.width - 4)
	self.linesOffset = 0
	self.linesBelowContent = self.lines.len - dlog.contentHeight
	self.draw = function
		dlog.drawSimpleValue self
	end function
	self.handleKey = function(k)
		if k.code == 19 then  // up
			self.scrollUp
			return true
		else if k.code == 20 then  // down
			self.scrollDown
			return true
		end if
	end function
	self.setCursor = function(hIndex, vIndex) ; end function
	self.wheelDown = function
		self.scrollDown
	end function
	self.wheelUp = function
		self.scrollUp
	end function
end function
InspectDialogValue.scrollDown = function
	if self.linesBelowContent > 0 then
		self.linesOffset += 1
		self.linesBelowContent -= 1
	end if
end function
InspectDialogValue.scrollUp = function
	if self.linesOffset > 0 then
		self.linesOffset -= 1
		self.linesBelowContent += 1
	end if
end function
InspectDialogValue.initContainerValue = function(value, dlog)
	InspectDialogValue = outer.InspectDialogValue
	valueWidth = dlog.width - 5 - self.keyWidth
	self.kLines = []
	self.vLines = []
	for k in self.sortedKeys
		self.kLines.push str(@k)[:self.keyWidth]
		self.vLines.push str(value[@k])[:valueWidth]
	end for
	self.linesOffset = 0
	self.linesBelowContent = self.sortedKeys.len - dlog.contentHeight
	if self.sortedKeys.len > 0 then self.cursor = 0
	self.draw = function
		dlog.drawContainerValue self
	end function
	self.handleKey = function(k)
		if k.code == 19 then  // up
			self.cursorUp
			return true
		else if k.code == 20 then  // down
			self.cursorDown dlog.contentHeight
			return true
		else if k.code == 17 then  // left
			if not self.isAtKey then self.isAtKey = true
			return true
		else if k.code == 18 then  // right
			if self.isAtKey then self.isAtKey = false
			return true
		else if k.code == 10 then  // return
			oldValueInfo = dlog.valueInfo
			dlog.valueInfo = (new InspectDialogValue).init(self.valueUnderCursor, dlog)
			dlog.valueInfo.parent = oldValueInfo
			return true
		end if
	end function
	self.setCursor = function(hIndex, vIndex)
		if vIndex + self.linesOffset >= self.sortedKeys.len then return false
		self.cursor = vIndex + self.linesOffset
		self.isAtKey = hIndex < self.keyWidth
		return true
	end function
	self.wheelDown = function
		self.cursorDown dlog.contentHeight
	end function
	self.wheelUp = function
		self.cursorUp
	end function
end function
InspectDialogValue.cursorUp = function
	if self.cursor != null and self.cursor > 0 then
		self.cursor -= 1
		if self.linesOffset > self.cursor then
			self.linesOffset -= 1
			self.linesBelowContent += 1
		end if
	end if
end function
InspectDialogValue.cursorDown = function(contentHeight)
	if self.cursor != null and self.cursor + 1 < self.sortedKeys.len then
		self.cursor += 1
		if self.cursor >= self.linesOffset + contentHeight then
			self.linesOffset += 1
			self.linesBelowContent -= 1
		end if
		return true
	end if
end function
InspectDialogValue.valueUnderCursor = function
	if self.cursor == null then return
	key = self.sortedKeys[self.cursor]
	if self.isAtKey then return @key
	return self.value[@key]
end function

InspectDialog.make = function(value)
	dlog = textUtil.Dialog.make("Inspect value")
	dlog.__isa = InspectDialog
	dlog.height = dlog.contentHeight + 8
	dlog.okBtn.caption = "Inspect (Ret)"
	dlog.okBtn.visible = true
	dlog.altBtn.caption = "Current (c)"
	dlog.altBtn.visible = true
	dlog.altBtn.key = "c"
	dlog.cancelBtn.caption = "Initial (Esc)"
	dlog.cancelBtn.visible = true
	dlog.backBtn = new textUtil.DialogButton
	dlog.backBtn.caption = "Back (b)"
	dlog.backBtn.visible = false
	dlog.backBtn.key = "b"
	dlog.backBtn.x = dlog.left + 2
	dlog.backBtn.y = dlog.top - 1
	dlog.valueInfo = (new InspectDialogValue).init(@value, dlog)
	return dlog
end function

InspectDialog.drawContent = function(cols, rows)
	self._cols = cols
	self._rows = rows
	text.setCell self._cols, self._rows, " "
	text.setCellBackColor self._cols, self._rows, self.backColor
	value = @self.valueInfo.value
	typeRow = self.top - 1
	self.center = self.left + self.width / 2
	text.color = self.textColor; text.backColor = self.backColor
	textUtil.printCenteredAt self.center, typeRow, self.valueInfo.type
	if self.valueInfo.parent != null then
		self.backBtn.visible = true
		text.color = "#CCCCCC"
		self.backBtn.draw
	else
		self.backBtn.visible = false
	end if
	self.valueInfo.draw
end function

InspectDialog.drawSimpleValue = function(dlogValue)
	vCols = self._cols[2:-2]
	vRows = self._rows[5:-3]
	text.setCell vCols, vRows, " "
	text.setCellBackColor vCols, vRows, self.valueBackground
	if dlogValue.linesOffset > 0 then
		text.color = self.textColor; text.backColor = self.backColor
		textUtil.printCenteredAt self.center, self._rows[-3], "Press ↑ to scroll"
	end if
	if dlogValue.linesBelowContent > 0 then
		text.color = self.textColor; text.backColor = self.backColor
		textUtil.printCenteredAt self.center, self._rows[4], "Press ↓ to scroll"
	end if
	lines = dlogValue.lines[dlogValue.linesOffset : dlogValue.linesOffset + self.contentHeight]
	text.color = self.valueColor ; text.backColor = self.valueBackground
	for i in lines.indexes
		textUtil.printAt vCols[0], vRows[-1 - i], lines[i]
	end for
	self.okBtn.visible = false
	self.altBtn.visible = (dlogValue.parent != null)
	self.cancelBtn.visible = true
end function

InspectDialog.drawContainerValue = function(dlogValue)
	kCols = self._cols[2 : 2 + dlogValue.keyWidth]
	vCols =  self._cols[2 + dlogValue.keyWidth + 1 : -2]
	vRows = self._rows[5:-3]
	text.setCell kCols, vRows, " "
	text.setCellBackColor kCols, vRows, self.valueBackground
	text.setCell vCols, vRows, " "
	text.setCellBackColor vCols, vRows, self.valueBackground
	if dlogValue.linesOffset > 0 then
		text.color = self.textColor; text.backColor = self.backColor
		textUtil.printCenteredAt self.center, self._rows[-3], "Move cursor up to scroll"
	end if
	if dlogValue.linesBelowContent > 0 then
		text.color = self.textColor; text.backColor = self.backColor
		textUtil.printCenteredAt self.center, self._rows[4], "Move cursor down to scroll"
	end if
	kLines = dlogValue.kLines[dlogValue.linesOffset : dlogValue.linesOffset + self.contentHeight]
	vLines = dlogValue.vLines[dlogValue.linesOffset : dlogValue.linesOffset + self.contentHeight]
	if dlogValue.cursor != null then
		cursor = dlogValue.cursor - dlogValue.linesOffset
	else
		cursor = -1
	end if
	cursorBackColor = color.lerp(self.valueColor, color.black)
	if cursor >= 0 then
		cursorRow = vRows[-1 - cursor]
		if dlogValue.isAtKey then
			text.setCellBackColor kCols, cursorRow, self.valueColor
			text.setCellBackColor vCols, cursorRow, cursorBackColor
		else
			text.setCellBackColor kCols, cursorRow, cursorBackColor
			text.setCellBackColor vCols, cursorRow, self.valueColor
		end if
	end if
	for i in kLines.indexes
		if i != cursor then
			text.color = self.valueColor ; text.backColor = self.valueBackground
		else if dlogValue.isAtKey then
			text.color = self.valueBackground ; text.backColor = self.valueColor
		else
			text.color = self.valueColor ; text.backColor = cursorBackColor
		end if
		textUtil.printAt kCols[0], vRows[-1 - i], kLines[i]
		if i != cursor then
			text.color = self.valueColor ; text.backColor = self.valueBackground
		else if not dlogValue.isAtKey then
			text.color = self.valueBackground ; text.backColor = self.valueColor
		else
			text.color = self.valueColor ; text.backColor = cursorBackColor
		end if
		textUtil.printAt vCols[0], vRows[-1 - i], vLines[i]
	end for
	if dlogValue.cursor != null then
		text.color = self.textColor; text.backColor = self.backColor
		underCursor = dlogValue.valueUnderCursor
		textUtil.printCenteredAt self.center, self._rows[3], "cursor at: " + InspectDialogValue.getTypeString(@underCursor)
	end if
	self.okBtn.visible = true
	self.altBtn.visible = (dlogValue.parent != null)
	self.cancelBtn.visible = true
end function

InspectDialog.handleKey = function(k)
	if k.code == 27 then
		info = self.valueInfo
		while info.parent
			info = info.parent
		end while
		self.cancelBtn.payload = @info.value
		return null
	else if k == self.altBtn.key and self.altBtn.visible then
		self.altBtn.payload = @self.valueInfo.value
		return null
	else if k == self.backBtn.key and self.backBtn.visible then
		self.valueInfo = self.valueInfo.parent
		self.draw
		return true
	end if
	isHandled = self.valueInfo.handleKey(k)
	if isHandled then self.draw
	return isHandled
end function

InspectDialog.handleMouse = function
	if self.backBtn.visible and self.backBtn.contains(mouse) then
		if self.backBtn.trackHit then
			self.valueInfo = self.valueInfo.parent
			self.draw
			return true
		end if
	end if
	if self.okBtn.visible and self.okBtn.contains(mouse) then
		if self.okBtn.trackHit then
			oldValueInfo = self.valueInfo
			self.valueInfo = (new InspectDialogValue).init(self.valueInfo.valueUnderCursor, self)
			self.valueInfo.parent = oldValueInfo
			self.draw
			return true
		end if
	end if
	if self.cancelBtn.visible and self.cancelBtn.contains(mouse) then
		info = self.valueInfo
		while info.parent
			info = info.parent
		end while
		self.cancelBtn.payload = @info.value
		return null
	end if
	if self.altBtn.visible and self.altBtn.contains(mouse) then
		self.altBtn.payload = @self.valueInfo.value
		return null
	end if
	hIndex = self._cols[2:-2].indexOf(textUtil.textCol(mouse.x))
	vIndex = self._rows[5:-3].indexOf(textUtil.textRow(mouse.y))
	if hIndex != null and vIndex != null and self.valueInfo.setCursor(hIndex, self.contentHeight - vIndex - 1) then
		self.draw
		return true
	end if
	return false
end function

InspectDialog.handleMouseWheel = function(axisValue)
	if axisValue > 0 then
		self.valueInfo.wheelDown
	else
		self.valueInfo.wheelUp
	end if
	self.draw
end function

if locals == globals then
	d = InspectDialog.make({"a": 1.79769313486231570e+308, "b": [null, @PixelDisplay.drawImage, 1/0, 0/0, text, Display, file.readLines("/sys/tips.txt").join(char(13))] + ["foo"] * 20})
	btn = d.show
	obj = @btn.payload
	print "You selected: " + str(@obj).ellideEnd(53)
end if
