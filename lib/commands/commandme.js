(function() {
  var CommandReply, Icommand,
    extend = function(child, parent) { for (var key in parent) { if (hasProp.call(parent, key)) child[key] = parent[key]; } function ctor() { this.constructor = child; } ctor.prototype = parent.prototype; child.prototype = new ctor(); child.__super__ = parent.prototype; return child; },
    hasProp = {}.hasOwnProperty;

  Icommand = require('../icommand.js');

  CommandReply = (function(superClass) {
    extend(CommandReply, superClass);

    function CommandReply() {}

    CommandReply.prototype.handle = function(sender, text, args, storage, textRouter, commandManager) {
      var message, success;
      if (args.length === 1 || (args.length === 2 && args[1] === "")) {
        return false;
      }
      message = args.slice(1).join(" ");
      message = message.replace(/\\n/g, "\n");
      message = message.split(/[\r\n]+/g).map(function(item) {
        return "\u0001ACTION " + item + " \u0001";
      }).join("\n");
      commandManager.sendChannel(sender, textRouter, message);
      success = true;
      return success;
    };

    CommandReply.prototype.help = function(commandPrefix) {
      return ["make this bot to say some message", "this command will send to you according to where you exec this command, Usage", commandPrefix + " messages.."];
    };

    CommandReply.prototype.hasPermission = function(sender, text, args, storage, textRouter, commandManager) {
      return true;
    };

    return CommandReply;

  })(Icommand);

  module.exports = CommandReply;

}).call(this);
