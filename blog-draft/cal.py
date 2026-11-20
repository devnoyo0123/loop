import zlib, struct, sys
def read_png(path):
    data = open(path,'rb').read()
    pos = 8; idat = b''; w=h=ct=None
    while pos < len(data):
        ln = struct.unpack('>I', data[pos:pos+4])[0]
        typ = data[pos+4:pos+8]
        chunk = data[pos+8:pos+8+ln]
        if typ == b'IHDR': w,h,bd,ct,c,f,i = struct.unpack('>IIBBBBB', chunk)
        elif typ == b'IDAT': idat += chunk
        elif typ == b'IEND': break
        pos += 12 + ln
    raw = zlib.decompress(idat)
    ch = {0:1,2:3,3:1,4:2,6:4}[ct]
    stride = w*ch
    out = bytearray(h*stride); prev = bytearray(stride); p = 0
    for y in range(h):
        f = raw[p]; p += 1
        line = bytearray(raw[p:p+stride]); p += stride
        if f == 1:
            for i in range(ch, stride): line[i] = (line[i] + line[i-ch]) & 255
        elif f == 2:
            for i in range(stride): line[i] = (line[i] + prev[i]) & 255
        elif f == 3:
            for i in range(stride):
                a = line[i-ch] if i >= ch else 0
                line[i] = (line[i] + ((a + prev[i]) >> 1)) & 255
        elif f == 4:
            for i in range(stride):
                a = line[i-ch] if i >= ch else 0
                b = prev[i]; c = prev[i-ch] if i >= ch else 0
                pa, pb, pc = abs(b-c), abs(a-c), abs(a+b-2*c)
                pr = a if (pa<=pb and pa<=pc) else (b if pb<=pc else c)
                line[i] = (line[i] + pr) & 255
        out[y*stride:(y+1)*stride] = line; prev = line
    return w, h, ch, out
def find(path, cond):
    w, h, ch, px = read_png(path)
    xs=[]; ys=[]
    for y in range(0, h, 2):
        row = y*w*ch
        for x in range(0, w, 2):
            i = row + x*ch
            if cond(px[i],px[i+1],px[i+2]): xs.append(x); ys.append(y)
    if not xs: return None
    return ((min(xs)+max(xs))//4.0, (min(ys)+max(ys))//4.0)
mag = find(sys.argv[1], lambda r,g,b: r>200 and b>200 and g<90)
print(f"{mag[0]:.1f} {mag[1]:.1f}" if mag else "NONE")
