\open ::Combinators
\open ::Data::Either
\open ::Data::Nat::Base
\open ::Data::Nat::Compare
\open ::Data::Unit
\open ::Paths


-- Term definition

\data FTerm (V : \Set)
    | FVar V
    | FApp (FTerm V) (FTerm V)
    | FLam (FTerm (Either V Unit))


-- Functor structure

\function
fmap
    {V W : \Set}
    (f : V -> W)
    (t : FTerm V) : FTerm W <= \elim t
        | FVar v        => FVar (f v)
        | FApp t1 t2    => FApp (fmap f t1) (fmap f t2)
        | FLam t        => FLam (fmap (map-inl f) t)


-- Monad structure

\function
return
    {V : \Set}
    (v : V) : FTerm V => FVar v


\function
bind-fun-helper
    {V W : \Set}
    (k : V -> FTerm W)
    (e : Either V Unit) : FTerm (Either W Unit) <= \elim e
        | inl v     => fmap {W} {Either W Unit} inl (k v)
        | inr unit  => FVar (inr unit)


\function
bind
    {V W : \Set}
    (t : FTerm V)
    (k : V -> FTerm W) : FTerm W <= \elim t
        | FVar x        => k x
        | FApp t1 t2    => FApp (t1 `bind` k) (t2 `bind` k)
        | FLam t        => FLam (t `bind` (bind-fun-helper k))



--  Functor laws and related

\function
map-inl-respects-id
    {L R : \Set}
    (e : Either L R) : map-inl (\lam x => x) e = e <= \elim e
        | inl l => idp
        | inr r => idp


\function
map-inl-respects-comp
    {A B C R : \Set}
    (f : A -> B)
    (g : B -> C)
    (e : Either A R) : map-inl g (map-inl f e) = map-inl (g `o` f) e <= \elim e
        | inl l => idp
        | inr r => idp


-- Утверждение 4 из раздела 2.3
\function
fmap-respects-id
    {V : \Set}
    (t : FTerm V) : fmap (\lam x => x) t = t <= \elim t
        | FVar v => idp
        | FApp t1 t2 => pmap2 FApp (fmap-respects-id t1) (fmap-respects-id t2)
        | FLam t => \let
                        | rec => fmap-respects-id t
                        | fext => funExt (\lam _ => Either V Unit) (\lam x => x) (map-inl (\lam x => x)) (\lam e => inv (map-inl-respects-id e))
                        | rect => transport (\lam x => fmap {Either V Unit} {Either V Unit} x t = t) fext rec
                    \in pmap FLam rect


-- Утверждение 5 из раздела 2.3
\function
fmap-respects-comp
    {A B C : \Set}
    (f : A -> B)
    (g : B -> C)
    (t : FTerm A) : fmap g (fmap f t) = fmap (g `o` f) t <= \elim t
        | FVar v => idp
        | FApp t1 t2 => pmap2 FApp (fmap-respects-comp f g t1) (fmap-respects-comp f g t2)
        | FLam t => \let
                        | rec => fmap-respects-comp (map-inl {A} {B} {Unit} f) (map-inl {B} {C} {Unit} g) t
                        | fext => funExt (\lam _ => Either C Unit) (\lam x => map-inl {B} {C} {Unit} g (map-inl {A} {B} f x)) (map-inl (g `o` f)) (map-inl-respects-comp f g)
                        | trrec => transport (\lam x => fmap (map-inl {B} {C} {Unit} g) (fmap (\lam (e : Either A Unit) => map-inl {A} {B} {Unit} f e) t) = fmap x t) fext rec
                    \in pmap FLam trrec


-- Helper lemmata

\function
return-right-unit-funext-helper
    {V : \Set}
    (e : Either V Unit) : return e = (bind-fun-helper return) e <= \elim e
        | inl v => idp
        | inr unit => idp


\function
bind-fun-helper-fmap-comm
    {A B : \Set}
    (f : A -> FTerm B)
    (x : Either A Unit) : bind-fun-helper (bind-fun-helper f) (map-inl inl x) = fmap (map-inl inl) (bind-fun-helper f x) <= \elim x
        | inl a     => inv (bind-fmap-comm-rhs-fext-helper-lemma (f a) (inl))
        | inr unit  => idp


\function
bind-fmap-comm-rhs-fext-helper-lemma-fext-helper
    {B C : \Set}
    (f : B -> C)
    (x : Either B Unit) : map-inl {Either B Unit} {Either C Unit} {Unit} (\lam (e : Either B Unit) => map-inl {B} {C} {Unit} f e) (map-inl {B} {Either B Unit} {Unit} inl x) = map-inl {C} {Either C Unit} {Unit} inl (map-inl {B} {C} {Unit} f x) <= \elim x
        | inl b => idp
        | inr unit => idp



\function
bind-fmap-comm-rhs-fext-helper-lemma
    {B C : \Set}
    (t : FTerm B)
    (f : B -> C) : fmap (map-inl {B} {C} {Unit} f) (fmap {B} {Either B Unit} inl t) = fmap {C} {Either C Unit} inl (fmap f t) <= \elim t
        | FVar b        => idp
        | FApp t1 t2    => pmap2 FApp (bind-fmap-comm-rhs-fext-helper-lemma t1 f) (bind-fmap-comm-rhs-fext-helper-lemma t2 f)
        | FLam t        =>  \let
                                | rec   => bind-fmap-comm-rhs-fext-helper-lemma t (map-inl f)
                                | comp1 => fmap-respects-comp (map-inl {_} {_} {Unit} inl) (map-inl {_} {_} {Unit} (map-inl {B} {C} {Unit} f)) t
                                | comp2 => fmap-respects-comp (map-inl {B} {C} {Unit} f) (map-inl {C} {Either C Unit} {Unit} inl) t
                                | fext  => funExt (\lam _ => Either (Either C Unit) Unit) (\lam x => map-inl {Either B Unit} {Either C Unit} {Unit} (map-inl {B} {C} {Unit} f) (map-inl {B} {Either B Unit} {Unit} inl x)) (\lam x => map-inl {C} {Either C Unit} {Unit} inl (map-inl {B} {C} {Unit} f x)) (bind-fmap-comm-rhs-fext-helper-lemma-fext-helper f)
                                | trans => comp1 *> (pmap (\lam x => fmap x t) fext) *> (inv comp2)
                            \in pmap FLam trans


\function
bind-fmap-comm-rhs-fext-helper
    {A B C : \Set}
    (f : B -> C)
    (k : A -> FTerm B)
    (x : Either A Unit) : fmap (map-inl {B} {C} {Unit} f) (bind-fun-helper k x) = bind-fun-helper (\lam y => fmap f (k y)) x <= \elim x
        | inl a => bind-fmap-comm-rhs-fext-helper-lemma (k a) f
        | inr unit => idp


-- Лемма 3 из раздела 2.3
\function
bind-fmap-comm-rhs
    {A B C : \Set}
    (t : FTerm A)
    (f : B -> C)
    (k : A -> FTerm B) : fmap f (t `bind` k) = t `bind` (\lam x => fmap f (k x)) <= \elim t
        | FVar a        => idp
        | FApp t1 t2    => pmap2 FApp (bind-fmap-comm-rhs t1 f k) (bind-fmap-comm-rhs t2 f k)
        | FLam t        =>  \let
                                | rec => bind-fmap-comm-rhs t (map-inl {B} {C} {Unit} f) (bind-fun-helper k)
                                | fext => funExt (\lam _ => FTerm (Either C Unit)) (\lam x => fmap (map-inl {B} {C} {Unit} f) (bind-fun-helper k x)) (\lam e => bind-fun-helper (\lam x => fmap f (k x)) e) (bind-fmap-comm-rhs-fext-helper f k)
                                | trrec => transport (\lam u => fmap (map-inl {B} {C} {Unit} f) (bind t (bind-fun-helper k)) = u) (pmap (bind t) fext) rec
                            \in pmap FLam trrec


\function
bind-fmap-comm-lhs-fext-helper
    {A B C : \Set}
    (f : A -> B)
    (k : B -> FTerm C)
    (x : Either A Unit) : bind-fun-helper k (map-inl {A} {B} {Unit} f x) = bind-fun-helper (\lam y => k (f y)) x <= \elim x
        | inl a => idp
        | inr unit => idp


-- Лемма 2 из раздела 2.3
\function
bind-fmap-comm-lhs
    {A B C : \Set}
    (t : FTerm A)
    (f : A -> B)
    (k : B -> FTerm C) : fmap f t `bind` k = t `bind` (k `o` f) <= \elim t
        | FVar a        => idp
        | FApp t1 t2    => pmap2 FApp (bind-fmap-comm-lhs t1 f k) (bind-fmap-comm-lhs t2 f k)
        | FLam t        =>  \let
                                | rec => bind-fmap-comm-lhs t (map-inl {A} {B} {Unit} f) (bind-fun-helper k)
                                | fext => funExt (\lam _ => FTerm (Either C Unit)) (\lam x => bind-fun-helper k (map-inl {A} {B} {Unit} f x)) (\lam e => bind-fun-helper (\lam x => k (f x)) e) (bind-fmap-comm-lhs-fext-helper f k)
                                | trrec => transport (\lam u => (fmap (map-inl {A} {B} {Unit} f) t) `bind` (bind-fun-helper k) = u) (pmap (bind t) fext) rec
                            \in pmap FLam trrec

-- Лемма 4 из раздела 2.3
\function
bind-fmap-comm
    {A B : \Set}
    (t : FTerm  A)
    (f : A -> FTerm B) : bind (fmap {A} {Either A Unit} inl t) (bind-fun-helper f) = fmap {B} {Either B Unit} inl (bind t f) <= \elim t
        | FVar v        => idp
        | FApp t1 t2    => pmap2 FApp (bind-fmap-comm t1 f) (bind-fmap-comm t2 f)
        | FLam t        => \let
                                | lhs => bind-fmap-comm-lhs t (map-inl inl) (bind-fun-helper (bind-fun-helper f))
                                | rhs => bind-fmap-comm-rhs t (map-inl inl) (bind-fun-helper f)
                                | fext => funExt (\lam _ => FTerm (Either (Either B Unit) Unit)) (\lam x => bind-fun-helper (bind-fun-helper f) (map-inl inl x)) (\lam x => fmap (map-inl inl) (bind-fun-helper f x)) (bind-fun-helper-fmap-comm f)
                                | trans => lhs *> (pmap (bind t) fext) *> (inv rhs)
                           \in pmap FLam trans


\function
bind-assoc-funext-helper
    {A B C : \Set}
    (f : A -> FTerm B)
    (g : B -> FTerm C)
    (x : Either A Unit) : bind ((bind-fun-helper f) x) (bind-fun-helper g) = bind-fun-helper (\lam a => bind (f a) g) x <= \elim x
        | inl a     => bind-fmap-comm (f a) g
        | inr unit  => idp


-- Monad laws
-- Утверждение 6 из раздела 2.3
\function
return-right-unit
    {V : \Set}
    (t : FTerm V) : t `bind` return = t <= \elim t
        | FVar v        => idp
        | FApp t1 t2    => pmap2 FApp (return-right-unit t1) (return-right-unit t2)
        | FLam t        =>  \let
                                | rec       => return-right-unit t
                                | funext    => funExt (\lam _ => FTerm (Either V Unit)) return (bind-fun-helper return) return-right-unit-funext-helper
                                | trrec     => transport (\lam x => bind t x = t) funext rec
                            \in pmap FLam trrec


-- Утверждение 7 из раздела 2.3
\function
return-left-unit
    {V W : \Set}
    (x : V)
    (k : V -> FTerm W) : ((return x) `bind` k = k x) => idp


-- Утверждение 8 из раздела 2.3
\function
bind-assoc
    {A B C : \Set}
    (f : A -> FTerm B)
    (g : B -> FTerm C)
    (t : FTerm A) : (t `bind` f) `bind` g = t `bind` (\lam x => (f x) `bind` g) <= \elim t
        | FVar v        => idp
        | FApp t1 t2    => pmap2 FApp (bind-assoc f g t1) (bind-assoc f g t2)
        | FLam t        =>  \let
                                | f'    => bind-fun-helper f
                                | g'    => bind-fun-helper g
                                | rec   => bind-assoc f' g' t
                                | fext  => funExt (\lam _ => FTerm (Either C Unit)) (\lam x => (f' x) `bind` g') (bind-fun-helper (\lam x => (f x) `bind` g)) (bind-assoc-funext-helper f g)
                                | trrec => transport (\lam x => (t `bind` f') `bind` g' = t `bind` x) fext rec
                            \in pmap FLam trrec
