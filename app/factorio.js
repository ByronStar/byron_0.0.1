let myCanvas, ctx, icons;

function init() {
    myCanvas = document.getElementById('thecanvas');
    ctx = myCanvas.getContext('2d');

    ctx.fillStyle = 'gray';
    ctx.fillRect(0, 0, 800, 800);
    ctx.beginPath();
    ctx.moveTo(20, 20);
    ctx.lineTo(20, 100);
    ctx.lineTo(70, 100);
    ctx.stroke();

    icons = document.getElementById('icons');
    placeIcon(6,6,4,4)
}

function placeIcon(iX, iY, x, y) {
    const s = 64
    ctx.drawImage(icons, iX * 66, iY * 66, s, s, x * 64, y * 64, s, s);
}