import { action } from "@ember/object";
import Component from "@glimmer/component";
import { tracked } from "@glimmer/tracking";
import { inject as service } from "@ember/service";
import { ajax } from "discourse/lib/ajax";
import { popupAjaxError } from "discourse/lib/ajax-error";

export function buildAnchorId(commentId) {
  return `post-voting-comment-${commentId}`;
}

export default class PostVotingComment extends Component {
  @tracked isEditing = false;
  @tracked isVoting = false;

  get anchorId() {
    return buildAnchorId(this.args.comment.id);
  }

  @action
  onSave(comment) {
    this.args.updateComment(comment);
    this.collapseEditor();
  }

  @action
  onCancel() {
    this.collapseEditor();
  }

  @action
  removeVote() {
    this.isVoting = true;

    this.args.removeVote(this.args.comment.id);

    return ajax("/post_voting/vote/comment", {
      type: "DELETE",
      data: { comment_id: this.args.comment.id },
    })
      .catch((e) => {
        this.args.vote(this.args.comment.id);
        popupAjaxError(e);
      })
      .finally(() => {
        this.isVoting = false;
      });
  }

  @action
  vote(direction) {
    if (direction !== "up") {
      return;
    }

    this.isVoting = true;

    this.args.vote(this.args.comment.id);

    return ajax("/post_voting/vote/comment", {
      type: "POST",
      data: { comment_id: this.args.comment.id },
    })
      .catch((e) => {
        this.args.removeVote(this.args.comment.id);
        popupAjaxError(e);
      })
      .finally(() => {
        this.isVoting = false;
      });
  }

  @action
  expandEditor() {
    this.isEditing = true;
  }

  @action
  collapseEditor() {
    this.isEditing = false;
  }
}
