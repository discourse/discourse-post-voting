import { action } from "@ember/object";
import Component from "@glimmer/component";
import { inject as service } from "@ember/service";
import { popupAjaxError } from "discourse/lib/ajax-error";
import { ajax } from "discourse/lib/ajax";
import I18n from "I18n";
import PostVotingFlag from "../lib/post-voting-flag";
import FlagModal from "discourse/components/modal/flag";

export default class PostVotingCommentActions extends Component {
  @service dialog;
  @service modal;
  @service currentUser;
  @service siteSettings;
  @service site;

  comment = this.args.comment;

  get canEdit() {
    return (
      this.currentUser &&
      (this.comment.user_id === this.currentUser.id ||
        this.currentUser.admin ||
        this.currentUser.moderator) &&
      !this.args.disabled
    );
  }

  get canFlag() {
    debugger;
    return (
      this.currentUser &&
      (this.comment.user_id === this.currentUser.id ||
        this.currentUser.admin ||
        this.currentUser.moderator ||
        this.currentUser.trust_level >=
          this.siteSettings.min_trust_to_flag_posts_voting_comments) &&
      !this.args.disabled
    );
  }

  @action
  deleteConfirm() {
    this.dialog.deleteConfirm({
      message: I18n.t("post_voting.post.post_voting_comment.delete.confirm"),
      didConfirm: () => {
        const data = { comment_id: this.args.id };

        ajax("/post_voting/comments", {
          type: "DELETE",
          data,
        })
          .then(() => {
            this.args.removeComment(this.args.id);
          })
          .catch(popupAjaxError);
      },
    });
  }

  @action
  showFlag() {
    this.comment.availableFlags = this.comment.available_flags;
    debugger;
    this.modal.show(FlagModal, {
      model: {
        flagTarget: new PostVotingFlag(),
        flagModel: this.comment,
        setHidden: () => this.comment.set("hidden", true),
        site: this.site,
      },
    });
  }
}
