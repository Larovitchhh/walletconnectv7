;; --------------------------------------------------
;; LEVEL 7 - VIP MEMBERSHIP NFT (AppKit Optimized)
;; --------------------------------------------------

;; 1. Definir el NFT (Sin depender de traits externos para evitar errores de nodo)
(define-non-fungible-token VIP-MEMBER uint)

;; 2. Constantes de Seguridad
(define-constant ERR-NOT-AUTHORIZED (err u401))
(define-constant ERR-NOT-VIP (err u403))
(define-constant ERR-ALREADY-MINTED (err u406))
(define-constant VIP-THRESHOLD u10000000) ;; 10 STX

;; 3. Variables de Estado
(define-data-var last-id uint u0)
(define-data-var owner principal tx-sender)

;; 4. Mapas para el Frontend (AppKit)
(define-map user-contributions principal uint)
(define-map minted-wallets principal bool)

;; --- FUNCIONES PÚBLICAS ---

;; Donar STX para subir de rango
(define-public (donate-stx (amount uint))
    (let (
        (current-total (default-to u0 (map-get? user-contributions tx-sender)))
    )
        (asserts! (> amount u0) (err u100))
        ;; Transferencia directa al owner
        (try! (stx-transfer? amount tx-sender (var-get owner)))
        ;; Actualizar progreso
        (map-set user-contributions tx-sender (+ current-total amount))
        (ok true)
    )
)

;; Reclamar NFT de Socio (Solo VIPs)
;; Esta función es la que llamarás desde el botón "Claim" en tu dApp con Reown
(define-public (claim-membership)
    (let (
        (total-donated (default-to u0 (map-get? user-contributions tx-sender)))
        (next-id (+ (var-get last-id) u1))
    )
        ;; VALIDACIÓN 1: ¿Ha donado suficiente?
        (asserts! (>= total-donated VIP-THRESHOLD) ERR-NOT-VIP)
        ;; VALIDACIÓN 2: ¿Ya tiene el NFT? (Evitar duplicados)
        (asserts! (is-none (map-get? minted-wallets tx-sender)) ERR-ALREADY-MINTED)

        ;; MINTEAR NFT
        (try! (nft-mint? VIP-MEMBER next-id tx-sender))
        
        ;; Actualizar estado
        (var-set last-id next-id)
        (map-set minted-wallets tx-sender true)
        (ok next-id)
    )
)

;; --- FUNCIONES DE LECTURA (Para tu UI de Reown) ---

(define-read-only (get-membership-status (user principal))
    (let (
        (donated (default-to u0 (map-get? user-contributions user)))
        (has-nft (default-to false (map-get? minted-wallets user)))
    )
    {
        donated-amount: donated,
        is-eligible: (>= donated VIP-THRESHOLD),
        has-claimed: has-nft,
        next-vip-id: (+ (var-get last-id) u1)
    })
)

(define-read-only (get-nft-owner (id uint))
    (ok (nft-get-owner? VIP-MEMBER id))
)
