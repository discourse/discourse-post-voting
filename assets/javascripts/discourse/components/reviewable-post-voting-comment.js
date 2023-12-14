import Component from "@glimmer/component";
import { tracked } from "@glimmer/tracking";
import { inject as service } from "@ember/service";

export default class ReviewableChatMessage extends Component {
  @service store;
  @tracked post;

  constructor() {
    super(...arguments);
    this.store.find("post", this.args.reviewable.post_id).then((post) => {
      this.post = post;
    });
  }
}
