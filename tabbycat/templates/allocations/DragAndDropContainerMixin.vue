<script>
// Provides shared functionality common across the container components for editing
// adjs/teams/venues etc
import { mapGetters } from 'vuex'

import DragAndDropDebate from '../../templates/allocations/DragAndDropDebate.vue'
import DragAndDropLayout from '../../templates/allocations/DragAndDropLayout.vue'
import DragAndDropActions from '../../templates/allocations/DragAndDropActions.vue'
import WebsocketMixin from '../../templates/ajax/WebSocketMixin.vue'

export default {
  mixins: [WebsocketMixin],
  components: { DragAndDropDebate, DragAndDropLayout, DragAndDropActions },
  props: ['initialData'],
  data: function () {
    return {
      // Connect to all relevant round sockets. We determine all unique
      // round sequences present in the initial debates/panels data so that
      // this page also receives updates for concurrent elimination rounds.
      sockets: (() => {
        try {
          const currentSeq = (this.initialData && this.initialData.round) ? this.initialData.round.seq : null
          const seqs = new Set()
          if (this.initialData && Array.isArray(this.initialData.debatesOrPanels)) {
            this.initialData.debatesOrPanels.forEach(d => {
              if (d && d.round_seq !== undefined && d.round_seq !== null) {
                seqs.add(String(d.round_seq))
              }
            })
          }
          // Ensure current round first for sending actions
          const ordered = []
          if (currentSeq !== null) {
            ordered.push(`debates:${currentSeq}`)
          }
          for (const s of Array.from(seqs).sort((a, b) => Number(a) - Number(b))) {
            const label = `debates:${s}`
            if (!ordered.includes(label)) {
              ordered.push(label)
            }
          }
          // Fallback for contexts without round metadata
          if (ordered.length === 0) {
            ordered.push('debates')
          }
          return ordered
        } catch (e) {
          return ['debates']
        }
      })(),
    }
  },
  created: function () {
    // Initial mutation to the Vuex store that sets up the initial state
    this.$store.commit('setupInitialData', this.initialData)
    this.$store.commit('setupWebsocketBridge', this.bridges[this.sockets[0]])
  },
  computed: {
    ...mapGetters(['allDebatesOrPanels', 'sortedDebatesOrPanels']),
    debatesOrPanelsCount: function () {
      return Object.keys(this.allDebatesOrPanels).length
    },
    tournamentSlugForWSPath: function () {
      return this.initialData.tournament.slug
    },
    roundSlugForWSPath: function () {
      return this.initialData.round.seq
    },
    unallocatedItems: function () {
      // Filters the global list of items based upon the state of each individual debate
      const allocatedItemIDs = []
      const allDebatesOrPanels = this.$store.getters.allDebatesOrPanels
      for (const keyPanel of Object.entries(allDebatesOrPanels)) {
        allocatedItemIDs.push(...this.getUnallocatedItemFromDebateOrPanel(keyPanel[1]))
      }
      const unallocatedItems = []
      const allUnallocatedItems = this.$store.getters.allocatableItems
      for (const [id, adjudicator] of Object.entries(allUnallocatedItems)) {
        if (!allocatedItemIDs.includes(Number(id))) {
          unallocatedItems.push(adjudicator)
        }
      }
      return unallocatedItems
    },
  },
  methods: {
    getPathAdditions: function (path, socketLabel) {
      // Override to support per-socket round routing when label is 'debates:<seq>'
      let label = socketLabel
      let seq = this.roundSlugForWSPath
      if (typeof socketLabel === 'string' && socketLabel.indexOf(':') !== -1) {
        const parts = socketLabel.split(':')
        label = parts[0]
        seq = parts[1]
      }
      if (this.tournamentSlugForWSPath !== undefined) {
        path += `${this.tournamentSlugForWSPath}/`
      }
      if (seq !== undefined) {
        path += `round/${seq}/`
      }
      path = `${path + label}/`
      return path
    },
    handleSocketReceive: function (socketLabel, payload) {
      this.$store.dispatch('receiveUpdatedupdateDebatesOrPanelsAttribute', payload)
    },
    showAllocate: function () {
      $('#confirmAllocateModal').modal('show')
    },
    showPrioritise: function () {
      $('#confirmPrioritiseModal').modal('show')
    },
  },
}
</script>
