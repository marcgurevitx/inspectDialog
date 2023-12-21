# Inspect dialog

`inspectDialog` is a Mini Micro library that provides a subclass of `textUtil.Dialog` that inspects MiniScript values.

See this blog post on how to use it: https://dev.to/joestrout/a-holiday-gift-inspect-dialog-for-mini-micro-14bd (by [Joe Strout](https://github.com/JoeStrout)).

### Quick ref

Create a dialog instance and inspect a value:

```
import "inspectDialog"

d = inspectDialog.InspectDialog.make({"foo": 42, "bar": 420})
d.show
```

Simple helper for a startup.ms file:

```
inspect = function(value)
	import "inspectDialog"
	dlog = inspectDialog.InspectDialog.make(@value)
	btn = dlog.show
	return @btn.payload
end function
```

How it will look in Mini Micro:

![How it will look](doc/inspect.gif)
