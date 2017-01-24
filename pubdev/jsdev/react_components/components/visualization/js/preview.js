// Generated by CoffeeScript 1.11.1
(function() {
  var Preview, React,
    extend = function(child, parent) { for (var key in parent) { if (hasProp.call(parent, key)) child[key] = parent[key]; } function ctor() { this.constructor = child; } ctor.prototype = parent.prototype; child.prototype = new ctor(); child.__super__ = parent.prototype; return child; },
    hasProp = {}.hasOwnProperty;

  React = require('react');

  Preview = (function(superClass) {
    extend(Preview, superClass);

    function Preview(props) {
      Preview.__super__.constructor.call(this, props);
      console.log("Preview constructor");
      this.state = {
        content: ""
      };
    }

    Preview.prototype.output = function(str) {
      return this.setState({
        content: str
      });
    };

    Preview.prototype.render = function() {
      var div, pre, ref;
      ref = React.DOM, div = ref.div, pre = ref.pre;
      console.log("Preview render");
      return div({
        id: "revl-preview",
        onKeyDown: this.props.revl.keyDown,
        onKeyPress: this.props.revl.keyPress
      }, pre({}, this.state.content));
    };

    return Preview;

  })(React.Component);

  module.exports = React.createFactory(Preview);

}).call(this);

//# sourceMappingURL=preview.js.map
