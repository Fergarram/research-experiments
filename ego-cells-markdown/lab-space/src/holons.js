import { makeid } from './utils.js';

let HOLONS = [];
let RELATIONSHIPS = {};

function addHolons(list) {
	HOLONS = list.map((name, i) => ({
		name,
		relations: {},
		ui: {
			id: makeid(),
			x: 16 + (i * 16),
			y: 128 + (i * 16),
			// visible: i === 0 || i === 10 
			visible: false
		}
	}));
};

function addRelationship(name, complement) {
	RELATIONSHIPS[name] = { complement };
}

function holon(name, relationship, others) {
	const i = HOLONS.findIndex(h => h.name === name);
	HOLONS[i].relations[relationship] = others;
	others.forEach(oname => {
		const j = HOLONS.findIndex(h => h.name === oname);
		const existingRelations = HOLONS[j].relations[RELATIONSHIPS[relationship].complement];

		if (!existingRelations) {
			HOLONS[j].relations[RELATIONSHIPS[relationship].complement] = [];
			HOLONS[j].relations[RELATIONSHIPS[relationship].complement].push(name);

		} else if (existingRelations && !existingRelations.includes(name)) {
			HOLONS[j].relations[RELATIONSHIPS[relationship].complement].push(name);
		}
	});
}


//
// Markdown specific stuff
//

const markdown = [
	'CH_SPACE',
	'CH_ABC',
	'CH_123',
	'CH_DOT',
	'CH_HASH',
	'CH_DASH',
	'CH_TICK',
	'CH_ASTERISK',
	'CH_VOID',

	'TK_TEXT',
	'TK_H1',
	'TK_H2',
	'TK_H3',
	'TK_H4',
	'TK_H5',
	'TK_H6',
	'TK_UL_ITEM',
	'TK_OL_ITEM',
	'TK_BOLD',
	'TK_BOLD_CONTENT',
	'TK_SNIP_START',
	'TK_SNIP_END',
	'TK_SNIP_CONTENT',
	'TK_NULL',

	'BL_H1',
	'BL_H2',
	'BL_H3',
	'BL_H4',
	'BL_H5',
	'BL_H6',
	'BL_PARAGRAPH',
	'BL_UL_LIST',
	'BL_OL_LIST',
	'BL_SNIPPET',
	'BL_EMPTY_LINE',
];

addHolons(markdown);

// "canBeMadeOf" complementary relationship is "canBePartOf"
addRelationship('canBeMadeOf', 'canBePartOf');

for (let i = 1; i < 7; i++) {
	// We can see here how this requires truths from another space, in this
	// case it's the spatial neighbors.
	holon(`TK_H${i}`, 'canBeMadeOf', [ 'CH_HASH', 'CH_SPACE', 'CH_VOID' ]);
}

holon('TK_TEXT', 'canBeMadeOf', markdown.filter(item => item.includes('CH_') && item !== 'CH_VOID'));
holon('TK_SNIP_CONTENT', 'canBeMadeOf', markdown.filter(item => item.includes('CH_') && item !== 'CH_VOID'));
holon('TK_BOLD_CONTENT', 'canBeMadeOf', markdown.filter(item => item.includes('CH_') && item !== 'CH_ASTERISK' && item !== 'CH_VOID'));

holon('TK_BOLD', 'canBeMadeOf', [ 'CH_ASTERISK' ]);

holon('TK_UL_ITEM', 'canBeMadeOf', [
	'CH_ASTERISK',
	'CH_SPACE',
	'CH_DASH',
]);

holon('TK_OL_ITEM', 'canBeMadeOf', [
	'CH_123',
	'CH_DOT',
	'CH_SPACE',
]);

holon('TK_NULL', 'canBeMadeOf', [ 'CH_SPACE' ]);

holon('BL_PARAGRAPH', 'canBeMadeOf', [
	'TK_TEXT',
	'TK_BOLD',
	'TK_BOLD_CONTENT',
]);

for (let i = 1; i < 7; i++) {
	holon(`BL_H${i}`, 'canBeMadeOf', [ `TK_H${i}`, 'TK_TEXT', ]);
}

holon('BL_UL_LIST', 'canBeMadeOf', [
	'TK_UL_ITEM',
	'TK_TEXT'
]);

holon('BL_OL_LIST', 'canBeMadeOf', [
	'TK_OL_ITEM',
	'TK_TEXT'
]);

holon('BL_SNIPPET', 'canBeMadeOf', [
	'TK_SNIP_START',
	'TK_SNIP_CONTENT',
	'TK_SNIP_END',
]);

holon('BL_EMPTY_LINE', 'canBeMadeOf', [ 'TK_NULL' ]);

export { HOLONS, RELATIONSHIPS };