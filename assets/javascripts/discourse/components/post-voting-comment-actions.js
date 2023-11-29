import Component from "@glimmer/component";
import { action } from "@ember/object";
import { inject as service } from "@ember/service";
import { ajax } from "discourse/lib/ajax";
import { popupAjaxError } from "discourse/lib/ajax-error";
import I18n from "I18n";

export default class PostVotingCommentActions extends Component {
  @service dialog;

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
}
