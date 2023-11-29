import Component from "@glimmer/component";
import { tracked } from "@glimmer/tracking";
import { action } from "@ember/object";
import { inject as service } from "@ember/service";
import I18n from "I18n";

export default class PostVotingCommentComposer extends Component {
  @service siteSettings;

  @tracked value = this.args.raw ?? "";

  @action
  onInput(event) {
    this.value = event.target.value;
    this.args.onInput?.(event.target.value);
  }

  get errorMessage() {
    if (this.value.length < this.siteSettings.min_post_length) {
      return I18n.t("post_voting.post.post_voting_comment.composer.too_short", {
        count: this.siteSettings.min_post_length,
      });
    }

    if (
      this.value.length > this.siteSettings.post_voting_comment_max_raw_length
    ) {
      return I18n.t("post_voting.post.post_voting_comment.composer.too_long", {
        count: this.siteSettings.post_voting_comment_max_raw_length,
      });
    }
  }

  get remainingCharacters() {
    return (
      this.siteSettings.post_voting_comment_max_raw_length - this.value.length
    );
  }
}
