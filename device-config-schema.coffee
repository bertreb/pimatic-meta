module.exports = {
  title: "pimatic metasensors devices config schemas"
  MetasensorsPresence:
    title: "MetasensorsPresence config"
    type: "object"
    extensions: ["xLink", "xConfirm", "xPresentLabel", "xAbsentLabel"]
    properties:
      autoReset:
        description: "Enable this if you want to set the metasensor to absent when all included sensors are absent."
        type: "boolean"
        default: false
      resetTime:
        description: "Time after the metasensor is set to 'absent' after last trigger"
        type: "number"
        default: 10000
      andTrigger:
      	description: "If enabled the metasensor will become 'present' only when all included sensors are triggered"
      	type: "boolean"
      	default: false
      includes:
        description: "List of Presence or Contact sensor id's to be included in the metasensor"
        type: "array"
        default: []
        items:
          type: "string"
  MetasensorsSwitch:
    title: "MetasensorsSwitch config"
    type: "object"
    extensions: ["xLink", "xConfirm", "xOnLabel", "xOffLabel"]
    properties:
      includes:
        description: "List of Switch actuator id's to be included in the metasensor"
        type: "array"
        default: []
        items:
          type: "string"
}