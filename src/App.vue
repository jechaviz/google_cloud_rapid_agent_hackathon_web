<template>
  <div class="min-h-screen">
    <header class="bg-[#101827] text-white border-b-4 border-[#35a853]">
      <div class="mx-auto max-w-7xl px-5 py-5">
        <div class="flex flex-wrap items-end justify-between gap-4">
          <div>
            <p class="m-0 text-sm text-[#a8c7fa] font-700">Google Cloud Rapid Agent Hackathon</p>
            <h1 class="m-0 mt-1 text-4xl font-900 leading-tight">AegisOps Incident Agent</h1>
          </div>
          <div class="flex gap-2 text-sm font-800">
            <span class="rounded bg-[#1a73e8] px-3 py-2">Gemini</span>
            <span class="rounded bg-[#35a853] px-3 py-2">Dynatrace MCP</span>
            <span class="rounded bg-[#fbbc04] px-3 py-2 text-[#17202a]">Cloud Run</span>
          </div>
        </div>
      </div>
    </header>

    <section class="mx-auto grid max-w-7xl grid-cols-1 gap-5 px-5 py-5 lg:grid-cols-[420px_1fr]">
      <aside class="rounded border border-[#d8e0e8] bg-white p-4 shadow-sm">
        <h2 class="m-0 text-lg font-900">Incident Intake</h2>
        <Field label="Title" v-model="incident.title" />
        <Field label="Service" v-model="incident.service" />
        <label class="mt-3 block text-xs font-900 text-[#5f6f7f]">Severity</label>
        <select v-model="incident.severity" class="mt-1 w-full rounded border border-[#d8e0e8] p-2">
          <option>SEV-1</option>
          <option>SEV-2</option>
          <option>SEV-3</option>
          <option>SEV-4</option>
        </select>
        <label class="mt-3 block text-xs font-900 text-[#5f6f7f]">Symptoms</label>
        <textarea v-model="symptomsText" class="mt-1 h-28 w-full rounded border border-[#d8e0e8] p-2"></textarea>
        <label class="mt-3 block text-xs font-900 text-[#5f6f7f]">Suspected change</label>
        <textarea v-model="incident.suspected_change" class="mt-1 h-20 w-full rounded border border-[#d8e0e8] p-2"></textarea>
        <button @click="runAgent" :disabled="busy" class="mt-4 w-full rounded bg-[#1a73e8] px-4 py-3 font-900 text-white disabled:opacity-60">
          {{ busy ? 'Running triage' : 'Run triage' }}
        </button>
      </aside>

      <main class="grid gap-5">
        <section class="grid grid-cols-1 gap-4 md:grid-cols-3">
          <Metric title="Prod Readiness" :value="run ? 'candidate' : 'ready'" />
          <Metric title="Action Mode" value="approval gated" />
          <Metric title="Evidence" :value="run ? run.evidence.digest_sha256.slice(0, 10) : 'pending'" />
        </section>

        <section class="grid grid-cols-1 gap-5 xl:grid-cols-[minmax(0,1fr)_360px]">
          <div class="rounded border border-[#d8e0e8] bg-white p-4 shadow-sm">
            <div class="flex flex-wrap items-center justify-between gap-3">
              <h2 class="m-0 text-lg font-900">{{ run ? run.summary : 'Agent Run' }}</h2>
              <span class="rounded bg-[#e8f0fe] px-3 py-1 text-sm font-800 text-[#174ea6]">{{ status }}</span>
            </div>
            <div class="mt-4 grid gap-3">
              <article v-for="step in steps" :key="step.name" class="rounded border border-[#d8e0e8] border-l-4 border-l-[#35a853] p-3">
                <h3 class="m-0 text-base font-900">{{ step.name }}</h3>
                <p class="m-0 mt-1 text-sm text-[#5f6f7f]">{{ step.intent }}</p>
                <p class="m-0 mt-2 text-xs font-800 text-[#5f6f7f]">{{ step.tool }}</p>
              </article>
            </div>
          </div>
          <div class="rounded border border-[#d8e0e8] bg-white p-4 shadow-sm">
            <h2 class="m-0 text-lg font-900">Incident Topology</h2>
            <img src="./assets/incident-topology.svg" alt="Incident topology" class="mt-4 w-full">
            <div class="mt-4 grid gap-2 text-sm">
              <p class="m-0"><b>MCP:</b> {{ run?.mcp_integration?.selected || 'not run yet' }}</p>
              <p class="m-0"><b>Google:</b> {{ run?.google_integration?.cloud_runtime || 'Cloud Run compatible V backend' }}</p>
              <p class="m-0"><b>Gate:</b> human approval required</p>
            </div>
          </div>
        </section>

        <section class="rounded border border-[#d8e0e8] bg-[#0f172a] p-4 text-[#dceafe] shadow-sm">
          <pre class="m-0 max-h-[360px] overflow-auto whitespace-pre-wrap text-xs">{{ json }}</pre>
        </section>
      </main>
    </section>
  </div>
</template>

<script>
const apiBase = localStorage.getItem('aegisops_api') || 'http://127.0.0.1:8080';

const Field = {
  props: ['label', 'modelValue'],
  emits: ['update:modelValue'],
  template: `
    <label class="mt-3 block">
      <span class="block text-xs font-900 text-[#5f6f7f]">{{ label }}</span>
      <input class="mt-1 w-full rounded border border-[#d8e0e8] p-2" :value="modelValue" @input="$emit('update:modelValue', $event.target.value)">
    </label>`
};

const Metric = {
  props: ['title', 'value'],
  template: `
    <div class="rounded border border-[#d8e0e8] bg-white p-4 shadow-sm">
      <b class="text-xs text-[#5f6f7f]">{{ title }}</b>
      <span class="mt-2 block text-xl font-900">{{ value }}</span>
    </div>`
};

export default {
  components: { Field, Metric },
  data() {
    return {
      busy: false,
      status: 'ready',
      run: null,
      incident: {
        title: 'Checkout latency spike after canary release',
        service: 'checkout-api',
        severity: 'SEV-2',
        started_at: '2026-05-29T16:42:00Z',
        suspected_change: 'Cloud Run revision checkout-api-00042-q7f received 20 percent traffic',
        business_impact: 'Estimated 18 percent conversion drop for active retail cart sessions',
        constraints: ['No full rollback without incident commander approval']
      },
      symptomsText: [
        'p95 latency rose from 220ms to 2.8s in 12 minutes',
        'error budget burn is above 8x for checkout SLO',
        'support queue reports failed card authorizations'
      ].join('\n')
    };
  },
  computed: {
    steps() {
      return this.run?.plan || [];
    },
    json() {
      return this.run ? JSON.stringify(this.run, null, 2) : 'Run the agent to produce evidence JSON.';
    }
  },
  methods: {
    async runAgent() {
      this.busy = true;
      this.status = 'running';
      try {
        const payload = { ...this.incident, symptoms: this.symptomsText.split('\n').filter(Boolean) };
        const response = await fetch(`${apiBase}/api/agent/run`, {
          method: 'POST',
          headers: { 'Content-Type': 'application/json' },
          body: JSON.stringify(payload)
        });
        this.run = await response.json();
        this.status = 'evidence ready';
      } catch (error) {
        this.status = 'demo fallback';
        this.run = demoRun(String(error));
      } finally {
        this.busy = false;
      }
    }
  }
};

function demoRun(error) {
  return {
    run_id: 'demo-web-fallback',
    summary: 'SEV-2 on checkout-api: New canary revision correlates with latency and payment failures.',
    google_integration: {
      cloud_runtime: 'Cloud Run compatible V backend',
      model: 'gemini-2.5-flash',
      mode: 'demo'
    },
    mcp_integration: {
      mode: 'demo',
      selected: 'dynatrace.problems.investigate',
      tools: ['dynatrace.problems.investigate', 'dynatrace.dql.query']
    },
    plan: [
      { name: 'Stabilize intake', intent: 'Classify severity, impact and constraints.', tool: 'agent.policy' },
      { name: 'Observe production context', intent: 'Use Dynatrace MCP tools for problem context.', tool: 'Dynatrace MCP' },
      { name: 'Correlate release change', intent: 'Compare Cloud Run revision timing with symptoms.', tool: 'Cloud Run metrics' },
      { name: 'Plan guarded remediation', intent: 'Prepare reversible traffic shift with approval.', tool: 'Gemini planner' },
      { name: 'Package evidence', intent: 'Generate digest and audit trail.', tool: 'agent.evidence_pack' }
    ],
    evidence: {
      digest_sha256: '2fd7f5221f9115819f3865931ff2c9002289dbdcc2907fc468da3b5d213d013d'
    },
    backend_error: error
  };
}
</script>
