// sketch for a sproing vox

SinOsc s1;
SinOsc s2;
Envelope e1;

// s1 => e1 => s2 => dac;
s1 => e1 => dac;
s2 => e1;
e1.op(3);

e1.duration(400::ms);
s1.freq(220);
s2.freq(440);

s1.gain(1.0);
s2.gain(1.0);

for (0.0 => float g; g <= 1.0; 0.1 +=> g) {
    <<< "gain = ", g >>>;
    s1.gain(g);
    e1.keyOn(1);
    e1.duration() => now;
    e1.keyOff(1);
    e1.duration() => now;
}


