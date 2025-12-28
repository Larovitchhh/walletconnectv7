;; --------------------------------------------------
;; Level 7 - VIP Membership NFT (SIP-009 Standard)
;; --------------------------------------------------

;; Estándar NFT
(impl-trait 'SP2PABAF9FTAJYNFZH93XENAJ8FVY99RRM50D2JG9.nft-trait.nft-trait)

;; Constantes
(define-constant ERR-NOT-AUTHORIZED (err u401))
(define-constant ERR-NOT-VIP (err u403))
(define-constant ERR-ALREADY-MINTED (err u406))
(define-constant VIP-THRESHOLD u10000000) ;; 10 STX

;; Definición del NFT
(define-non-fungible-token VIP-Member uint)

;; Variables
(define-data-var last-token-id uint u0)
(define-data-var contract-owner principal tx-sender)

;; Mapas del sistema anterior
(define-map user-stats principal { amount: uint })
(define-map has-minted principal bool)

;; --- Funciones de NFT (Estándar SIP-009) ---

(define-read-only (get-last-token-id)
    (ok (var-get last-token-id))
)

(define-read-only (get-token-uri (id uint))
    (ok (some "https://tu-api.com/metadata/vip.json"))
)

(define-read-only (get-owner (id uint))
    (ok (nft-get-owner? VIP-Member id))
)

(define-public (transfer (id uint) (sender principal) (recipient principal))
    (begin
        (assert! (is-eq tx-sender sender) ERR-NOT-AUTHORIZED)
        (nft-transfer? VIP-Member id sender recipient)
    )
)

;; --- Funciones de Lógica VIP ---

;; 1. Donar para ser VIP
(define-public (donate (amount uint))
    (let ((current-amount (get amount (default-to { amount: u0 } (map-get? user-stats tx-sender)))))
        (try! (stx-transfer? amount tx-sender (var-get contract-owner)))
        (map-set user-stats tx-sender { amount: (+ current-amount amount) })
        (ok true)
    )
)

;; 2. RECLAMAR NFT (Solo para VIPs)
;; Aquí es donde brilla AppKit con un botón de "Claim NFT"
(define-public (claim-membership-nft)
    (let (
        (stats (default-to { amount: u0 } (map-get? user-stats tx-sender)))
        (new-id (+ (var-get last-token-id) u1))
    )
        ;; Check: ¿Es VIP?
        (asserts! (>= (get amount stats) VIP-THRESHOLD) ERR-NOT-VIP)
        ;; Check: ¿Ya tiene uno?
        (asserts! (is-none (map-get? has-minted tx-sender)) ERR-ALREADY-MINTED)

        ;; Mintear NFT
        (try! (nft-mint? VIP-Member new-id tx-sender))
        
        ;; Actualizar estado
        (var-set last-token-id new-id)
        (map-set has-minted tx-sender true)
        (ok new-id)
    )
)

;; --- Lectura para el Frontend ---

(define-read-only (get-user-status (user principal))
    {
        total-donated: (get amount (default-to { amount: u0 } (map-get? user-stats user))),
        can-claim: (and (>= (get amount (default-to { amount: u0 } (map-get? user-stats user))) VIP-THRESHOLD) (is-none (map-get? has-minted user))),
        has-nft: (default-to false (map-get? has-minted user))
    }
)
