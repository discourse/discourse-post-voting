import { action } from "@ember/object";
import Component from "@glimmer/component";
import { tracked } from "@glimmer/tracking";
import { popupAjaxError } from "discourse/lib/ajax-error";
import { ajax } from "discourse/lib/ajax";
import { inject as service } from "@ember/service";

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
      value.length > this.siteSettings.qa_comment_max_raw_length;
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
