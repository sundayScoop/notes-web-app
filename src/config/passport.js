const passport = require('passport');
const LocalStrategy = require('passport-local').Strategy;
const User = require('../models/user');

passport.use(new LocalStrategy({
    usernameField: 'email',
    passwordField: 'password'
}, async (email, password, done)=>{

    console.log('[AUTH] Login attempt for email:', email);

    // Looking for registered email
    const user = await User.findOne({email});
    if(!user){
        console.log('[AUTH] No user found with email:', email);
        return done(null, false, { message: 'You are not registered.' })
    } else {
        console.log('[AUTH] User found:', user.name, '| email:', user.email);
        // Compare passwords
        const matchpass = await user.matchPass(password)
        console.log('[AUTH] Password match result:', matchpass);
        if (matchpass) {
            return done(null, user)
        } else {
            done(null, false, { message: 'Password do not match'})
        }
    }

}));

passport.serializeUser((user, done) =>{
    console.log('[AUTH] Serializing user:', user._id);
    done(null, user._id)
});

passport.deserializeUser(async (id, done)=>{
    try {
        const user = await User.findById(id);
        console.log('[AUTH] Deserialized user:', user ? user.email : 'NOT FOUND');
        done(null, user);
    } catch (err) {
        console.log('[AUTH] Deserialize error:', err);
        done(err);
    }
});