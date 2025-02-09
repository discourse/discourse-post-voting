import Component from "@glimmer/component";
import { tracked } from "@glimmer/tracking";
import { action } from "@ember/object";
import { service } from "@ember/service";
import { ajax } from "discourse/lib/ajax";
import { popupAjaxError } from "discourse/lib/ajax-error";

export default class PostVotingCommentsMenuComposer extends Component {
  @service siteSettings;

  @tracked value = "";
  @tracked submitDisabled = true;

  @action
  onKeyDown(e) {
    if (e.key === "Enter" && (e.ctrlKey || e.metaKey)) {
      this.saveComment();
    }
  }

  @action
  updateValue(value) {
    this.submitDisabled =
      value.length < this.siteSettings.min_post_length ||
      value.length > this.siteSettings.post_voting_comment_max_raw_length;
    this.value = value;
  }

  @action
  saveComment() {
    this.submitDisabled = true;

    return ajax("/post_voting/comments", {
      type: "POST",
      data: { raw: this.value, post_id: this.args.id },
    })
      .then((response) => {
        this.args.onSave(response);
        this.value = "";
      })
      .catch(popupAjaxError)
      .finally(() => {
        this.submitDisabled = false;
      });
  }
}
