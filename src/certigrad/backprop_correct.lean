/-
Copyright (c) 2017 Daniel Selsam. All rights reserved.
Released under Apache 2.0 license as described in the file LICENSE.
Author: Daniel Selsam

Main functional correctness theorem for stochastic backpropagation.
-/
import .util .graph .compute_grad .predicates .estimators .env .dvec .compute_grad_slow_correct .memoize_correct .lemmas .lemmas_extra

namespace certigrad
open tactic list theorems

theorem backprop_correct {costs : list ID} :
  ∀ {nodes : list node} (inputs : env) (tgts : list reference),
  ∀ {tgt : reference} {idx : ℕ}, at_idx tgts idx tgt →
  nodup (tgts ++ map node.ref nodes) →
  well_formed_at costs nodes inputs tgt →
  grads_exist_at nodes inputs tgt →
  pdfs_exist_at nodes inputs →
  is_gintegrable (λ m, ⟦compute_grad_slow costs nodes m tgt⟧) inputs nodes dvec.head →
  can_differentiate_under_integrals costs nodes inputs tgt →

  ∇ (λ θ₀, E (graph.to_dist (λ m, ⟦sum_costs m costs⟧) (env.insert tgt θ₀ inputs) nodes) dvec.head) (env.get tgt inputs)
  =
  E (graph.to_dist (λ m, backprop costs nodes m tgts) inputs nodes) (λ dict, dvec.get tgt.2 dict idx) :=

assume (nodes : list node) (inputs : env) (tgts : list reference)
       (tgt : reference) (idx : ℕ) (H_at_idx : at_idx tgts idx tgt)
       (H_nd : nodup (tgts ++ map node.ref nodes))
       (H_wf : well_formed_at costs nodes inputs tgt)
       (H_gs_exist : grads_exist_at nodes inputs tgt)
       (H_pdfs_exist : pdfs_exist_at nodes inputs)
       (H_grad_gint : is_gintegrable (λ m, ⟦compute_grad_slow costs nodes m tgt⟧) inputs nodes dvec.head)
       (H_diff_under_int : can_differentiate_under_integrals costs nodes inputs tgt),

have H_gdiff : is_gdifferentiable (λ m, ⟦sum_costs m costs⟧) tgt inputs nodes dvec.head, from
  is_gdifferentiable_of_pre _ _ _ H_wf H_gs_exist H_pdfs_exist H_diff_under_int,
have H_nabla_gint : is_nabla_gintegrable (λ m, ⟦sum_costs m costs⟧) tgt inputs nodes dvec.head, from
  is_nabla_gintegrable_of_gintegrable _ _ _ H_wf H_gs_exist H_pdfs_exist H_gdiff H_diff_under_int H_grad_gint,

begin
rw (compute_grad_slow_correct H_wf H_gs_exist H_pdfs_exist H_gdiff H_nabla_gint H_grad_gint H_diff_under_int),
rw (E.E_move_fn_to_continuation _ _ _ (λ dict, dvec.get tgt.2 dict idx)),
dunfold backprop, dsimp,
simp only [(λ m, tvec.get_from_env H_at_idx m), (λ m, memoize_correct costs nodes m H_at_idx H_nd)]
end


end certigrad
