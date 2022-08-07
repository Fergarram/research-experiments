<script>
	import markdownString from './markdown.js';
	import { HOLONS, RELATIONSHIPS } from './holons.js';
	import CardManager from './CardManager.svelte';
	import Card from './Card.svelte';

	const showUI = (name, toggle = false) => {
		const i = HOLONS.findIndex(h => h.name === name);
		HOLONS[i].ui.visible = toggle ? !HOLONS[i].ui.visible : true;
		setTimeout(() => {
			document.getElementById(HOLONS[i].ui.id).focus();
		}, 50);
	}
</script>


<header class="p-4">
	{#each HOLONS as h}
		<button
			on:click={() => showUI(h.name, true)}
			class="border border-gray-500 p-1 rounded-4 active:bg-gray-200 text-12 mb-1 mr-1 {h.ui.visible ? 'bg-blue-300' : 'bg-gray-100'}">
			{h.name}
		</button>
	{/each}
</header>

<CardManager>
	{#each HOLONS as h, index}
		{#if h.ui.visible}
			<Card bind:x={h.ui.x} bind:y={h.ui.y} classes="grid gap-2" cardId={h.ui.id}>
				<div class="font-medium pb-2 border-b border-gray-200 flex justify-between gap-4 items-center">
					{h.name}
					<p class="rounded-8 px-2 py-1 {h.relations['canBePartOf'] && h.relations['canBePartOf'].length > 1 ? 'bg-yellow-300' : 'bg-green-300'}">
						{#if h.relations['canBePartOf'] && h.relations['canBePartOf'].length > 1}
							Could be 1 in {h.relations['canBePartOf'].length} identities
						{:else}
							1 Possible Identity
						{/if}
					</p>
				</div>
				{#each Object.keys(h.relations) as r}
					<div>
						<p class="text-14">{r}</p>
						<ul class="grid">
							{#each h.relations[r] as link}
								<li
									non-draggable
									on:click={() => showUI(link)}
									class="inline-block w-fit text-blue-600 font-medium hover:underline cursor-auto">
									- {link}
								</li>
							{/each}
						</ul>
					</div>
				{/each}
				<div>
					<p class="text-14 mb-1 pt-1 mt-1 border-t border-gray-200">Neighboring Rules</p>
					<pre class="w-full overflow-auto bg-gray-800 text-white font-mono p-2 rounded-4">{`V <- H -> S\n---\nV = CH_VOID\nH = CH_HASH\nS = CH_SPACE`}</pre>
				</div>
			</Card>
		{/if}
	{/each}

	<!-- <Card x={16} y={window.innerHeight - 148} classes="grid gap-2">
		<p class="font-medium">
			QUERY HOLONS
		</p>
		<input
			non-draggable
			type="text"
			class="border border-gray-200 rounded-8 h-8 px-2"
			placeholder="Type query here..."
		/>
		<button
			non-draggable
			class="bg-blue-600 text-white px-2 py-1.5 rounded-8 active:bg-blue-700 cursor-auto">
			Run Query
		</button>
	</Card> -->

	<Card x={100} y={200}>
		<div class="grid gap-0.5">
			{#each markdownString.split('\n') as line}
				<div class="rounded-4 bg-gray-300 mr-0.5 inline-flex items-center">
					{#if line !== '\r'}
						{#each line.split(' ') as word}
							<div class="py-0.5 px-1.5 rounded-4 bg-gray-700 text-white mr-0.5 inline-flex">
								{#if word !== '\r'}
									<!-- {#if word.includes('-') && word.length > 1} -->
									{#if 0}
										{#each word.split('-') as comp, i}
											<div class="py-0.5 px-1.5 rounded-4 bg-yellow-500 text-gray-800 mr-0.5 inline-flex">
												{comp}
											</div>
											{#if word.split('-').length -1 !== i}
												<div class="py-0.5 px-1.5 rounded-4 bg-yellow-500 text-gray-800 mr-0.5 inline-flex">
													-
												</div>
											{/if}
										{/each}
									{:else}
										{word}
									{/if}
								{:else}
									<span class="bg-red-800">\n</span>
								{/if}
							</div>
						{/each}
					{:else}
						&nbsp;
					{/if}
				</div>
			{/each}
		</div>
	</Card>
</CardManager>

<style>
</style>