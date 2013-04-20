
$public class RTPing extends CommonRTPing
  constructor : ->
    super
    NET.define 'PING', read : server : (msg,src) =>
      msg.writeDoubleLE Date.now(), 2
      src.send msg
