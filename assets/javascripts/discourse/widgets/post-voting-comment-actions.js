import { createWidget } from "discourse/widgets/widget";
import I18n from "I18n";
import { popupAjaxError } from "discourse/lib/ajax-error";
import { ajax } from "discourse/lib/ajax";

createWidget("post-voting-comment-actions", {
  tagName: "span.post-voting-comment-actions",
  services: ["dialog"],

  html(attrs) {
    return [
      this.attach("link", {
        className: "post-voting-comment-actions-edit-link",
        action: "expandEditor",
        icon: "pencil-alt",
      }),
      this.attach("link", {
        className: "post-voting-comment-actions-delete-link",
        action: "deleteComment",
        icon: "far-trash-alt",
        actionParam: {
          comment_id: attrs.id,
        },
      }),
    ];
  },

  deleteComment(data) {
    this.dialog.deleteConfirm({
      message: I18n.t("post_voting.post.post_voting_comment.delete.confirm"),
      didConfirm: () => {
        ajax("/qa/comments", {
          type: "DELETE",
          data,
        })
          .then(() => {
            this.sendWidgetAction("removeComment", data.comment_id);
          })
          .catch(popupAjaxError);
      },
    });
  },
});
