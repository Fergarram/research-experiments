<script>
    import { onMount, getContext } from 'svelte';
    import { makeid } from './utils.js';

    export let x = 0;
    export let y = 0;
    export let classes = '';
    export let cardId = makeid();

    let card;
    const { addCard, moveCard, addListener, getStack } = getContext('cardStack');

    let cardIndex = addCard(cardId);
    addListener(() => {
        cardIndex = getStack().indexOf(cardId);
        if (card) card.style.zIndex = cardIndex;
    });

    let isDragging = false;
    let isTyping = false;
    let pos1 = 0, pos2 = 0, pos3 = 0, pos4 = 0;

    onMount(() => {
        card.onmousedown = dragMouseDown;
        card.style.transform = `translate3d(${(x)}px, ${(y)}px, 0)`;
    });

    const setPointerEventsFor = (element, option) => {
        // element.style.pointerEvents = option;
    };

    const dragMouseDown = (e) => {
        pos3 = e.clientX;
        pos4 = e.clientY;
        let isDraggable = e.target.getAttribute('non-draggable') === null;

        moveCard(cardId);

        document.onmousemove = (e) => {

            if (isDraggable) {
                pos1 = pos3 - e.clientX;
                pos2 = pos4 - e.clientY;
                pos3 = e.clientX;
                pos4 = e.clientY;
                let rect = card.getBoundingClientRect();
                x = (rect.left - pos1);
                y = (rect.top - pos2);
                card.style.transform = `translate3d(${x}px, ${y}px, 0)`;
                isDragging = true;
                setPointerEventsFor(card, "none");
            }

        }

        document.onmouseup = (e) => {
            isDragging = false;
            setPointerEventsFor(card, "initial")
            document.onmousemove = null
            document.onmouseup = null
        }
    }
</script>

<div
    bind:this={card}
    class="draggable"
    key={cardId}>
    <div
        id={cardId}
        tabindex="0"
        on:focus={() => moveCard(cardId)}
        class={`card ${isDragging && 'card--drag'}`}>
        <div class={classes}>
            <slot></slot>
        </div>
    </div>
</div>

<style>
    * {
        user-select: none;
    }
</style>