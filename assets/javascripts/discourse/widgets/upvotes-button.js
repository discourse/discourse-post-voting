import { createWidget } from "discourse/widgets/widget";
import { iconNode } from "discourse-common/lib/icon-library";

export default createWidget("upvotes-button", {
  tagName: "button.btn.btn-flat.no-text.upvotes-button",

  buildAttributes(attrs) {
    const attributes = {};

    if (attrs.loading) {
      attributes.disabled = "true";
    }

    return attributes;
  },

  buildClasses(attrs) {
    const result = [];

    if (attrs.direction === "up") {
      result.push("upvotes-button-upvote");
    }

    if (attrs.direction === "down") {
      result.push("upvotes-button-downvote");
    }

    if (attrs.voted) {
      result.push("upvotes-button-voted");
    }

    return result;
  },

  html(attrs) {
    return iconNode(`caret-${attrs.direction}`);
  },

  click() {
    if (this.attrs.loading) {
      return false;
    }

    this.sendWidgetAction(
      this.attrs.voted ? "removeVote" : "vote",
      this.attrs.direction
    );
  },
});
