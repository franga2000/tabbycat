<template>
  <draggable-item :drag-payload="dragPayload"
                  :class="[{ 'bg-dark text-white': !item.available }, highlightsCSS, venueConstraintsCSS, hoverVenueConstraintCSS]"
                  @mouseenter.native="onVenueMouseEnter" @mouseleave.native="onVenueMouseLeave">

      <span slot="number">
        <small class="pl-2 vue-draggable-muted ">{{ item.priority }}</small>
      </span>
      <span slot="title">
        {{ item.display_name }}
      </span>
      <span slot="subtitle">

      </span>

  </draggable-item>
</template>

<script>
import DraggableItem from '../../templates/allocations/DraggableItem.vue'
import HighlightableMixin from '../../templates/allocations/HighlightableMixin.vue'

export default {
  mixins: [HighlightableMixin],
  components: { DraggableItem },
  props: {
    item: Object,
    dragPayload: Object,
    debateOrPanelId: {
      type: Number,
      default: null,
    },
    isTrainee: {
      type: Boolean,
      default: false,
    },
  },
  computed: {
    highlightData: function () {
      return this.item
    },
    venueConstraintsCSS: function () {
      // If this venue is assigned to a debate, and any participant in that debate
      // has venue constraints that this venue's categories don't satisfy,
      // then show the red conflict styling.
      try {
        if (!this.debateOrPanelId || !this.item || !this.item.categories) {
          return ''
        }
        const constraints = this.$store.state.extra?.constraints?.debates?.[this.debateOrPanelId]
        if (!constraints || constraints.length === 0) {
          return ''
        }
        const venueCategoryIds = new Set(this.item.categories.map(c => (typeof c === 'object' ? c.id : c)))
        // constraints is an array of allowed category ID arrays, one per constrained subject present in the debate
        // If any subject's allowed set has no intersection with the venue's categories, it's a mismatch
        for (const allowedList of constraints) {
          let intersects = false
          for (const catId of allowedList) {
            if (venueCategoryIds.has(catId)) {
              intersects = true
              break
            }
          }
          if (!intersects) {
            return 'conflictable hover-adjudicator'
          }
        }
        return ''
      } catch (e) {
        return ''
      }
    },
    hoverVenueConstraintCSS: function () {
      try {
        const allowedSets = this.$store.getters.currentHoverVenueConstraintSets
        if (!allowedSets || allowedSets.length === 0) { return '' }
        const venueCategoryIds = new Set((this.item?.categories ?? []).map(c => (typeof c === 'object' ? c.id : c)))
        for (const allowed of allowedSets) {
          let intersects = false
          for (const cid of allowed) {
            if (venueCategoryIds.has(cid)) { intersects = true; break }
          }
          if (!intersects) {
            return 'conflictable hover-adjudicator'
          }
        }
        return ''
      } catch (e) {
        return ''
      }
    },
  },
  methods: {
    onVenueMouseEnter: function () {
      try {
        const cats = (this.item?.categories ?? []).map(c => (typeof c === 'object' ? c.id : c))
        this.$store.commit('setHoverVenue', { categories: cats, debateId: this.debateOrPanelId })
      } catch (e) {
        // noop
      }
    },
    onVenueMouseLeave: function () {
      this.$store.commit('unsetHoverVenue')
    },
  },
}
</script>
