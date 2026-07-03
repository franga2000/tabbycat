<template>
  <div class="text-truncate small px-1 py-1 inline-adjudicator d-flex align-items-center hover-target"
       :class="[highlightsCSS, conflictsCSS, hoverConflictsCSS, venueConstraintOutlineCSS]"
       @mouseenter="showHovers" @mouseleave="hideHovers">
    <div>{{ displayName }}<span v-if="symbol"> {{ symbol }}</span></div>
  </div>
</template>

<script>
import { mapState } from 'vuex'
import HighlightableMixin from '../../templates/allocations/HighlightableMixin.vue'
import HoverableConflictReceiverMixin from '../../templates/allocations/HoverableConflictReceiverMixin.vue'
import ConflictableAdjudicatorMixin from '../../templates/allocations/ConflictableAdjudicatorMixin.vue'

export default {
  name: 'InlineAdjudicator',
  mixins: [HighlightableMixin, HoverableConflictReceiverMixin, ConflictableAdjudicatorMixin],
  props: {
    adjudicator: { type: Object, required: true },
    debateId: { type: Number, required: true },
    role: { type: String, default: 'P' }, // C, P, T
  },
  computed: {
    ...mapState(['extra']),
    highlightData () {
      return this.adjudicator
    },
    displayName () {
      return this.adjudicator?.name || this.gettext('Unknown Adj')
    },
    symbol () {
      if (this.role === 'C') return 'Ⓒ'
      if (this.role === 'T') return 'Ⓣ'
      return ''
    },
    clashableType () { return 'adjudicator' },
    clashableID () { return this.adjudicator?.id ?? null },

    // Venue compatibility inputs
    assignedVenueCategoryIds () {
      try {
        const debate = this.$store.state.debatesOrPanels?.[this.debateId]
        if (!debate || !debate.venue) { return null }
        let venueObj = debate.venue
        if (typeof venueObj === 'number') {
          venueObj = this.$store.state.allocatableItems?.[venueObj]
        }
        const cats = venueObj?.categories ?? null
        if (!cats) { return null }
        return new Set(cats.map(c => (typeof c === 'object' ? c.id : c)))
      } catch (e) { return null }
    },
    adjudicatorAllowedSets () {
      try {
        const constraints = this.extra?.constraints
        if (!constraints) { return [] }
        const sets = []
        const adjCats = constraints.adjudicators?.[this.adjudicator.id]
        if (adjCats && adjCats.length > 0) sets.push(adjCats)
        const instId = this.adjudicator.institution
        const instCats = instId ? constraints.institutions?.[instId] : null
        if (instCats && instCats.length > 0) sets.push(instCats)
        return sets
      } catch (e) { return [] }
    },
    hoveredVenueCategories () {
      const cats = this.$store.getters.currentHoverVenueCategories
      if (!cats) return null
      return new Set(cats)
    },
    venueConstraintOutlineCSS () {
      const sets = this.adjudicatorAllowedSets
      if (!sets || sets.length === 0) return ''

      const isMismatchForCats = (catSet) => {
        if (!catSet) return false
        for (const allowed of sets) {
          let intersects = false
          for (const cid of allowed) { if (catSet.has(cid)) { intersects = true; break } }
          if (!intersects) return true
        }
        return false
      }

      if (isMismatchForCats(this.assignedVenueCategoryIds)) return 'conflictable panel-adjudicator'
      if (isMismatchForCats(this.hoveredVenueCategories)) return 'conflictable panel-adjudicator'
      return ''
    },
  },
  methods: {
    showHovers () {
      try {
        const sets = []
        const constraints = this.$store.state.extra?.constraints
        const adjCats = constraints?.adjudicators?.[this.adjudicator.id]
        if (adjCats && adjCats.length > 0) sets.push(adjCats)
        const instId = this.adjudicator.institution
        const instCats = instId ? constraints?.institutions?.[instId] : null
        if (instCats && instCats.length > 0) sets.push(instCats)
        this.$store.commit('setHoverVenueConstraints', { allowedSets: sets, debateId: this.debateId })
      } catch (e) { /* noop */ }
    },
    hideHovers () {
      this.$store.commit('unsetHoverVenueConstraints')
    },
  },
}
</script>
