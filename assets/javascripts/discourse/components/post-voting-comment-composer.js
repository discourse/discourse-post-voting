import { action } from "@ember/object";
import Component from "@glimmer/component";
import { tracked } from "@glimmer/tracking";
import { inject as service } from "@ember/service";

export default class PostVotingCommentComposer extends Component {
  @service siteSettings;

  @tracked value = this.args.raw ?? "";

  @action
  onInput(event) {
    this.value = event.target.value;
    this.args.onInput?.(event.target.value);
  }

  get isValueTooShort() {
    return (
      this.value.length > 0 &&
      this.value.length < this.siteSettings.min_post_length
    );
  }

  get isValueTooLong() {
    return this.value.length > this.siteSettings.qa_comment_max_raw_length;
  }

  get remainingCharacters() {
    return this.siteSettings.qa_comment_max_raw_length - this.value.length;
  }
}
