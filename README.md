# Inspect dialog

`inspectDialog` is a Mini Micro library that provides a subclass of `textUtil.Dialog` that inspects MiniScript values.


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