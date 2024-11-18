import Component from "@glimmer/component";
import { tracked } from "@glimmer/tracking";
import { service } from "@ember/service";

export default class ReviewablePostVotingComment extends Component {
  @service store;
  @tracked post;

  constructor() {
    super(...arguments);
    this.fetchPost();
  }
  async fetchPost() {
    const post = await this.store.find("post", this.args.reviewable.post_id);
    this.post = post;
  }
}
