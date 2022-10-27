import { createWidget } from "discourse/widgets/widget";
import I18n from "I18n";
import { popupAjaxError } from "discourse/lib/ajax-error";
import { ajax } from "discourse/lib/ajax";

createWidget("qa-comment-actions", {
  tagName: "span.qa-comment-actions",
  services: ["dialog"],

  html(attrs) {
    return [
      this.attach("link", {
        className: "qa-comment-actions-edit-link",
        action: "expandEditor",
        icon: "pencil-alt",
      }),
      this.attach("link", {
        className: "qa-comment-actions-delete-link",
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
      message: I18n.t("qa.post.qa_comment.delete.confirm"),
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
