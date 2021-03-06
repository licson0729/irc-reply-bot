(function() {
  var CommandNslookup, Icommand, dns, punycode,
    extend = function(child, parent) { for (var key in parent) { if (hasProp.call(parent, key)) child[key] = parent[key]; } function ctor() { this.constructor = child; } ctor.prototype = parent.prototype; child.prototype = new ctor(); child.__super__ = parent.prototype; return child; },
    hasProp = {}.hasOwnProperty;

  Icommand = require('../icommand.js');

  dns = require('dns');

  punycode = require('punycode');

  CommandNslookup = (function(superClass) {
    extend(CommandNslookup, superClass);

    function CommandNslookup() {
      this.avaliableTypes = ['A', 'AAAA', 'MX', 'NS', 'TXT', 'SRV', 'PTR', 'CNAME'];
    }

    CommandNslookup.prototype.handle = function(sender, text, args, storage, textRouter, commandManager) {
      var done, err, error, target, type;
      if (args.length === 1) {
        return false;
      }
      if (args.length === 2) {
        type = 'A';
        target = args[1];
      } else {
        type = args[1];
        target = args.slice(2).join(" ");
      }
      if (0 > this.avaliableTypes.indexOf(type)) {
        return false;
      }
      done = textRouter.async();
      try {
        dns.resolve(punycode.toASCII(target), type, (function(_this) {
          return function(err, addresses) {
            var i;
            if (err) {
              commandManager.sendPv(sender, textRouter, "Lookup : fail to resolve " + target + " in type " + type + " due to " + (err.toString()));
              return;
            }
            i = 0;
            while (i < addresses.length) {
              if ('string' !== typeof addresses[i]) {
                addresses[i] = JSON.stringify(addresses[i]);
              }
              addresses[i] = 'Lookup : ' + addresses[i];
              i++;
            }
            commandManager.sendPv(sender, textRouter, "Lookup : Results for " + target + " in type " + type + " :");
            addresses.forEach(function(address) {
              return commandManager.sendPv(sender, textRouter, address);
            });
            done();
          };
        })(this));
      } catch (error) {
        err = error;
        commandManager.sendPv(sender, textRouter, "Lookup : fail to resolve " + target + " in type " + type + " due to " + (err.toString()));
        done();
      }
      return true;
    };

    CommandNslookup.prototype.help = function(commandPrefix) {
      return ["make this bot to lookup a server, will send with private message. Usage", commandPrefix + " [" + (this.avaliableTypes.join('|')) + "] server"];
    };

    CommandNslookup.prototype.hasPermission = function(sender, text, args, storage, textRouter, commandManager) {
      return true;
    };

    return CommandNslookup;

  })(Icommand);

  module.exports = CommandNslookup;

}).call(this);
