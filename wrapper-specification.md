ev3dev Language Wrapper Specification (DRAFT ver `0.9.1`, rev 3)
===
This is an unofficial specification that defines a unified interface for language wrappers to expose the [ev3dev](http://www.ev3dev.org) device APIs. 

General Notes
---
Because this specification is meant to be implemented in multiple languages, the specific naming conventions of properties, methods and classes are not defined here. Depending on the language, names will be slightly different (ex. "touchSensor" or "TouchSensor" or "touch-sensor") so that they fit the language's naming conventions.

Some concepts that apply to multiple classes are described as "abstracts". These abstract sections explain how the class should handle specific situations, and do not necessarily translate in to their own class in the wrapper.

Implementation Notes (important)
---
- File access. There should be one class that is used or inherited from in all other classes that need to access object properties via file I/O. This class should check paths for validity, do basic error checking, and generally implement as much of the core I/O functionality as possible.
- Errors. All file access and other error-prone calls should be wrapped with error handling. If an error thrown by an external call is fatal, the wrapper should throw an error for the caller that states the error and gives some insight in to what actually happened.
- Naming conventions. All names should follow the language's naming conventions. Keep the names consistent, so that users can easily find what they want.

<hr/>

`Motor` (class) : abstract "IO Device"
-----
###Constructor:

Argument Name|Type|Description
---|---|---
Port|String|The port to control. Specify a blank string (or the undefined/null value for the language) for an automatic search. It is recommended to use the `OUTPUT_*` constants.
Type|String|The type of motor to accept. Can be left empty or undefined (in the languages that support it) to specify a wildcard.

###Direct attribute mappings:

Property Name|Type|Accessibility|Description
---|---|---|---
Duty Cycle|Number|Read
Duty Cycle SP|Number|Read/Write
Port Name|String|Read
Position|Number|Read/Write
Position Mode|String|Read/Write
Position SP|Number|Read/Write
Pulses Per Second|Number|Read
Pulses Per Second SP|Number|Read/Write
Ramp Down SP|Number|Read/Write
Ramp Up SP|Number|Read/Write
Regulation Mode|String|Read/Write
Run|Number|Read/Write
Run Mode|String|Read/Write
Speed Regulation P|Number|Read/Write
Speed Regulation I|Number|Read/Write
Speed Regulation D|Number|Read/Write
Speed Regulation K|Number|Read/Write
State|String|Read
Stop Mode|String|Read/Write
Stop Modes|String Array|Read
Time SP|Number|Read/Write
Type|String|Read

###Special properties:

Property Name|Type|Accessibility|Description
---|---|---|---
Device Index|Number|Read
Connected|Boolean|Read

###Methods:

Method Name|Return Type|Arguments|Description
---|---|---|---
Reset|Void|None|Sets the `reset` motor property to `1`, which causes the motor driver to reset all of the parameters.

<hr/>

`Sensor` (class) : abstract "IO Device"
-----
###Constructor:

Argument Name|Type|Description
---|---|---
Port|String|The port to control. Specify a blank string (or the undefined/null value for the language) for an automatic search. It is recommended to use the `INPUT_*` constants. 
Types|String Array|The types of sensors (device IDs) to allow. Leave the array empty or undefined (in the languages that support it) to specify a wildcard.

###Direct attribute mappings:

Property Name|Type|Accessibility|Description
---|---|---|---
Port Name|String|Read
Num Values|Number|Read
Type Name|String|Read
Mode|String|Read/Write
Modes|String Array|Read

###Special properties:

Property Name|Type|Accessibility|Description
---|---|---|---
Device Index|Number|Read
Connected|Boolean|Read

###Methods:

Method Name|Return Type|Arguments|Description
---|---|---|---
Get Value|Number (int)|Value Index : Number|Gets the raw value at the specified index
Get Float Value|Number (float)|Value Index : Number|Gets the value at the specified index, adjusted for the sensor's `dp` value

<hr/>

`I2C Sensor` (class) : extends `Sensor`
-----
###Constructor:

Argument Name|Type|Description
---|---|---
I2C Address (optional)|String|The I2C address that will be used to narrow down the search. Only necessary if multiple I2C devices are connected to the same port.

###Direct attribute mappings:

Property Name|Type|Accessibility|Description
---|---|---|---
Poll MS|Number|Read/Write
FW Version|String|Read

<hr/>

`Power Supply` (class)
-----
###Constructor:

Argument Name|Type|Description
---|---|---
Device (optional)|String|The name of the device to control (as listed in `/sys/class/power_supply/`). If left blank or unspecified, the default `legoev3-battery` should be used. `Connected` should be set to true if the device is found.

###Direct attribute mappings:

Property Name|Type|Accessibility|Description
---|---|---|---
Current Now|Number (int)|Read
Voltage Now|Number (int)|Read
Voltage Max Design|Number (int)|Read
Voltage Min Design|Number (int)|Read
Technology|String|Read
Type|String|Read

###Special properties:

Property Name|Type|Accessibility|Description
---|---|---|---
Current Amps|Number (float)|Read|The amount of current, in amps, coming from the device (`current_now` / 1000000)
Voltage Volts|Number (float)|Read|The number of volts (not µV) coming from the device (`voltage_now` / 1000000)
Connected|Boolean|Read

**NOTE:** The integer measures for current and voltage are in µA and µV, respectively, as returned from the sysfs attribute.

<hr/>

`LED` (class)
-----
###Constructor:

Argument Name|Type|Description
---|---|---
Device|String|The name of the device to control (as listed in `/sys/class/leds/`). `Connected` should be set to true if the device is found. If left blank or unspecified, `Connected` shold be set to false.

###Direct attribute mappings:

Property Name|Type|Accessibility|Description
---|---|---|---
Max Brightness|Number (int)|Read
Brightness|Number (int)|Read/Write
Trigger|String|Read/Write

###Special properties:

Property Name|Type|Accessibility|Description
---|---|---|---
Connected|Boolean|Read

<hr/>

Constants / Enums
---

Due to the inherent differences between the various languages that we support here, the enums listed below can also be declared as global constants.

###`Ports`

Name|Value|Description
---|---|---
`INPUT_AUTO`|instance-specific (see below for details)|Automatic input selection
`OUTPUT_AUTO`|instance-specific (see below for details)|Automatic output selection
`INPUT_1`|"in1"|Sensor port 1
`INPUT_2`|"in2"|Sensor port 2
`INPUT_3`|"in3"|Sensor port 3
`INPUT_4`|"in4"|Sensor port 4
`OUTPUT_A`|"outA"|Motor port A
`OUTPUT_B`|"outB"|Motor port B
`OUTPUT_C`|"outC"|Motor port C
`OUTPUT_D`|"outD"|Motor port D

The values for the `*_AUTO` constants can be chosen by the implementation. They can have any value that signifies an auto-search.

<hr/>

IO Device (abstract)
---
An IO Device handles control tasks for a single port or index. These  classes must chose one device out of the available ports to control. Given an IO port (in the constructor), an implementation should:

* If the specified port is blank or unspecified/undefined/null, the available devices should be enumerated until a suitable device is found. Any device is suitable when it's type is known to be compatible with the controlling class, and it meets any other requirements specified by the caller.
* If the specified port name is not blank, the available devices should be enumerated until a device is found that is plugged in to the specified port. The supplied port name should be compared directly to the value from the file, so that advanced port strings will match, such as `in1:mux3`.

All IO devices should have a `connected` variable. If a valid device is found while enumerating the ports, the `connected` variable should be set to `true` (by default, it should be false). If an error is thrown anywhere in the class, `connected` should be reset to false. If `connected` is false when an attempt is made to read from or write to a property file, an error should be thrown (except while in the consructor).


Compatibility
---
Starting after version `0.9.0`, we will be documenting the versions of ev3dev that the libraries are compatible with.

Compatibility table:

Language Binding Version|ev3dev Kernel Version(s)
---|---
`v0.9.1`| `3.16.1-3-ev3dev`+
