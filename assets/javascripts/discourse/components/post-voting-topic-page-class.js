import Component from "@ember/component";
import { scheduleOnce } from "@ember/runloop";
import { ORDER_BY_ACTIVITY_FILTER } from "../initializers/post-voting-edits";

export default Component.extend({
  tagName: "",

  didInsertElement() {
    this._super(...arguments);
    this._refreshClass();

    this.appEvents.on("post-voting-topic-updated", this, this._updateClass);
  },

  willDestroyElement() {
    this._super(...arguments);
    this._removeClass();
    this.appEvents.off("post-voting-topic-updated", this, this._updateClass);
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
      body.classList.add("post-voting-topic-sort-by-activity");
    } else {
      body.classList.add("post-voting-topic");
    }
  },

  _removeClass() {
    const body = document.getElementsByTagName("body")[0];
    body.classList.remove("post-voting-topic");
    body.classList.remove("post-voting-topic-sort-by-activity");
  },
});
