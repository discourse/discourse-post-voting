import Component from "@ember/component";
import { ORDER_BY_ACTIVITY_FILTER } from "../initializers/upvotes-edits";
import { scheduleOnce } from "@ember/runloop";

export default Component.extend({
  tagName: "",

  didInsertElement() {
    this._super(...arguments);
    this._refreshClass();

    this.appEvents.on("upvotes-topic-updated", this, this._updateClass);
  },

  willDestroyElement() {
    this._super(...arguments);
    this._removeClass();
    this.appEvents.off("upvotes-topic-updated", this, this._updateClass);
  },

  _refreshClass() {
    scheduleOnce("afterRender", this, this._updateClass);
  },

  _updateClass() {
    if (this.isDestroying || this.isDestroyed) {
      return;
    }

    const body = document.getElementsByTagName("body")[0];
    this._removeClass();

    if (this.topic.postStream.filter === ORDER_BY_ACTIVITY_FILTER) {
      body.classList.add("upvotes-topic-sort-by-activity");
    } else {
      body.classList.add("upvotes-topic");
    }
  },

  _removeClass() {
    const body = document.getElementsByTagName("body")[0];
    body.classList.remove("upvotes-topic");
    body.classList.remove("upvotes-topic-sort-by-activity");
  },
});
